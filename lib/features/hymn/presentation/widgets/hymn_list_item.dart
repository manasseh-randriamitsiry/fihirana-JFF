import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/core/utils/navigation_utility.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fihirana/shared/widgets/common/localization_extension.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';
import 'package:fihirana/app/theme/color_controller.dart';

class HymnListItem extends StatefulWidget {
  final Hymn hymn;
  final Color textColor;
  final Color backgroundColor;
  final VoidCallback onFavoritePressed;
  final VoidCallback? onMusicPressed;
  final bool isFirebaseHymn;

  const HymnListItem({
    super.key,
    required this.hymn,
    required this.textColor,
    required this.backgroundColor,
    required this.onFavoritePressed,
    this.onMusicPressed,
    this.isFirebaseHymn = false,
  });

  @override
  State<HymnListItem> createState() => _HymnListItemState();
}

class _HymnListItemState extends State<HymnListItem>
    with SingleTickerProviderStateMixin {
  final HymnService _hymnService = HymnService();
  final AudioService _audioService = AudioService.instance;
  bool _hasAudio = false;
  bool _audioChecked = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05,
    )..addListener(() {
        setState(() {});
      });
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Defer audio check to after initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAudioAvailability();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(_) {
    _scaleController.forward();
  }

  void _handleTapUp(_) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  Future<void> _checkAudioAvailability() async {
    // Always check audio availability for all hymns (including additional ones)
    // Use a delayed check to not block initial rendering
    Future.delayed(const Duration(milliseconds: 100), () async {
      if (!mounted) return;

      if (kDebugMode) {
        print('HymnListItem: Checking audio for hymn ${widget.hymn.id} (${widget.hymn.title})');
      }

      final hasAudio = await _audioService.checkAudioFileExists(widget.hymn.id);
      if (mounted) {
        if (kDebugMode) {
          print('HymnListItem: Audio check result for ${widget.hymn.id}: $hasAudio');
        }
        setState(() {
          _hasAudio = hasAudio;
          _audioChecked = true;
        });
      }
    });
  }

  Future<bool> _confirmDeletion(BuildContext context) async {
    final confirmationController = TextEditingController();
    bool isConfirmed = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: widget.backgroundColor,
              title: Text(
                context.translate((l) => l.deleteHymnQuestion),
                style: TextStyle(color: widget.textColor),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.translate(
                        (l) => l.confirmDeleteHymn(widget.hymn.title)),
                    style: TextStyle(color: widget.textColor),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmationController,
                    style: TextStyle(color: widget.textColor),
                    decoration: InputDecoration(
                      hintText:
                          context.translate((l) => l.yesLowercase),
                      hintStyle: TextStyle(
                          color: widget.textColor.withValues(alpha: 0.5)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        borderSide: BorderSide(color: widget.textColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        borderSide: BorderSide(color: widget.textColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.toLowerCase() == 'eny' ||
                          value.toLowerCase() == 'oui' ||
                          value.toLowerCase() == 'yes') {
                        isConfirmed = true;
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.translate(
                                  (l) => l.typeYesToConfirm),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(context.translate((l) => l.cancel),
                      style: TextStyle(color: widget.textColor)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(context.translate((l) => l.delete),
                      style: const TextStyle(color: Colors.red)),
                  onPressed: () {
                    if (confirmationController.text.toLowerCase() == 'eny') {
                      isConfirmed = true;
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
context
                                .translate((l) => l.typeYesToConfirm),
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );

    return isConfirmed;
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: widget.backgroundColor,
          title: Text(context.translate((l) => l.deleteHymnQuestion),
              style: TextStyle(color: widget.textColor)),
          content: Text(
            context.translate(
                (l) => l.confirmDeleteHymn(widget.hymn.title)),
            style: TextStyle(color: widget.textColor),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(context.translate((l) => l.no),
                  style: TextStyle(color: widget.textColor)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(context.translate((l) => l.yes),
                  style: const TextStyle(color: Colors.red)),
              onPressed: () async {
                // Capture the context and localized messages before any async operations
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final deleteHymnFailedMessage = context.translate((l) => l.deleteHymnFailed);
                final hymnDeletedSuccessMessage = context.translate((l) => l.hymnDeletedSuccess);
                final errorMessage = context.translate((l) => l.error);

                navigator.pop();

                final confirmed = await _confirmDeletion(context);

                // Check if widget is still mounted after async gap
                if (!mounted) return;

                if (!confirmed) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(deleteHymnFailedMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                try {
                  await _hymnService.deleteHymn(widget.hymn.id);

                  // Check if widget is still mounted after async operation
                  if (!mounted) return;

                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(hymnDeletedSuccessMessage),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // Check if widget is still mounted before showing error
                  if (!mounted) return;

                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('$errorMessage: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _playHymnAudio(BuildContext context) async {
    // Capture scaffold messenger and localization function before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final localizations = AppLocalizations.of(context);
    
    try {
      if (kDebugMode) {
        debugPrint('HymnListItem: Playing audio for ${widget.hymn.id}');
      }

      // If this hymn is already playing, just pause/resume
      if (_audioService.isHymnPlaying(widget.hymn.id)) {
        if (_audioService.isPlaying) {
          await _audioService.pause();
        } else {
          await _audioService.resume();
        }
      } else {
        // Otherwise, stop current and play new
        if (_audioService.currentPlayingHymnId.isNotEmpty) {
          await _audioService.stopCurrentAndPlayNew(widget.hymn);
        } else {
          await _audioService.playHymn(widget.hymn);
        }
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = localizations.errorPlayingAudio(e.toString());
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final authController = Get.find<AuthController>();
    final isAdmin = authController.isAdmin || authController.isSuperAdmin;
    // Access ColorController
    final controller = Get.find<ColorController>();

    // Using Obx to react to theme changes
    return Obx(() {
      final backgroundColor = controller.backgroundColor.value;
      final primaryColor = controller.primaryColor.value;
      final textColor = controller.textColor.value;
      
      // Replicate "Pastel" logic: Background + slight primary tint
      // This ensures it matches the theme but keeps the "card" look
      final pastelColor = Color.alphaBlend(
        primaryColor.withValues(alpha: 0.05),
        backgroundColor,
      );

      final textTheme = Theme.of(context).textTheme;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Listener(
          onPointerDown: _handleTapDown,
          onPointerUp: _handleTapUp,
          onPointerCancel: (_) => _handleTapCancel(),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: pastelColor, // Soft pastel background derived from controller
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), // Neutral shadow
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.hardEdge,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    NavigationUtility.navigateToDetailScreen(context, widget.hymn);
                  },
                  splashColor: primaryColor.withValues(alpha: 0.1),
                  highlightColor: primaryColor.withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Hymn Number Badge
                        Hero(
                          tag: 'hymn_number_${widget.hymn.id}',
                          child: Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.1), // Consistent accent/primary container
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              widget.hymn.hymnNumber,
                              style: textTheme.titleMedium?.copyWith(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Title and Preview
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Hero(
                                tag: 'hymn_title_${widget.hymn.id}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    widget.hymn.title,
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (widget.hymn.verses.isNotEmpty)
                                Text(
                                  widget.hymn.verses[0],
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: textColor.withValues(alpha: 0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                               if (isAdmin && widget.isFirebaseHymn)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      AppLocalizations.of(context).createdByLabel(
                                          widget.hymn.createdBy,
                                          widget.hymn.createdByEmail != null
                                              ? ' (${widget.hymn.createdByEmail})'
                                              : ''),
                                      style: textTheme.labelSmall?.copyWith(
                                        color: textColor.withValues(alpha: 0.5),
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                            ],
                          ),
                        ),

                        // Actions
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Audio Indicator
                            if (_audioChecked && _hasAudio)
                               Obx(() {
                                final isPlaying = _audioService.isHymnPlaying(widget.hymn.id);
                                return IconButton(
                                  onPressed: widget.onMusicPressed ?? () => _playHymnAudio(context),
                                  icon: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                     padding: const EdgeInsets.all(8),
                                     decoration: BoxDecoration(
                                       color: isPlaying ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                                       shape: BoxShape.circle,
                                     ),
                                    child: Icon(
                                      isPlaying ? Icons.graphic_eq : Icons.music_note_outlined,
                                      size: 20,
                                      color: isPlaying ? primaryColor : textColor.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  style: IconButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(40, 40),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                );
                               }),

                            // Favorite Button
                            StreamBuilder<Map<String, String>>(
                              stream: _hymnService.getFavoriteStatusStream(),
                              builder: (context, snapshot) {
                                final favoriteStatus = snapshot.data?[widget.hymn.id] ?? '';
                                final isFavorite = favoriteStatus.isNotEmpty;
                                return IconButton(
                                  onPressed: widget.onFavoritePressed,
                                  icon: Icon(
                                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: isFavorite ? Colors.redAccent : textColor.withValues(alpha: 0.6),
                                    size: 22,
                                  ),
                                  style: IconButton.styleFrom(
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                );
                              },
                            ),

                            // Admin Actions Menu
                            if (widget.isFirebaseHymn && isLoggedIn && (widget.hymn.createdByEmail == user.email || isAdmin))
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert_rounded, color: textColor.withValues(alpha: 0.6), size: 20),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    NavigationUtility.navigateToEditScreen(context, widget.hymn);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmation(context);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit_rounded, size: 20),
                                        const SizedBox(width: 12),
                                        Text(AppLocalizations.of(context).edit),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                                        const SizedBox(width: 12),
                                        Text(AppLocalizations.of(context).delete, style: const TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                color: backgroundColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
