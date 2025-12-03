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

      final hasAudio = await _audioService.checkAudioFileExists(widget.hymn.id);
      if (mounted) {
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
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: widget.textColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: widget.textColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
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
    final localizations = AppLocalizations.of(context)!;
    
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

    return Listener(
      onPointerDown: _handleTapDown,
      onPointerUp: _handleTapUp,
      onPointerCancel: (_) => _handleTapCancel(),
      child: Transform.scale(
        scale: _scaleAnimation.value,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: widget.backgroundColor,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical:4 ),
            title: Hero(
              tag: 'hymn_title_${widget.hymn.id}',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  widget.hymn.title,
                  style: TextStyle(
                    color: widget.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.hymn.verses.isNotEmpty)
                  Text(
                    widget.hymn.verses[0],
                    style: TextStyle(
                      color: widget.textColor.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (isAdmin && widget.isFirebaseHymn)
                  Text(
                    context.translate((l) => l.createdByLabel(
                        widget.hymn.createdBy,
                        widget.hymn.createdByEmail != null
                            ? ' (${widget.hymn.createdByEmail})'
                            : '')),
                    style: TextStyle(
                      color: widget.textColor.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            leading: Hero(
              tag: 'hymn_number_${widget.hymn.id}',
              child: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                radius: 25,
                child: Text(
                  widget.hymn.hymnNumber,
                  style: TextStyle(
                    color: widget.backgroundColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            trailing: SizedBox(
              width: 96,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_audioChecked && _hasAudio)
                    Obx(() {
                      final isPlaying =
                          _audioService.isHymnPlaying(widget.hymn.id);
                      if (kDebugMode) {
                        print(
                            'Hymn ${widget.hymn.id} playing status: $isPlaying');
                      }
                      return IconButton(
                        onPressed: widget.onMusicPressed ??
                            () {
                              // Default audio play behavior if no callback provided
                              _playHymnAudio(context);
                            },
                        style: IconButton.styleFrom(
                          backgroundColor: isPlaying
                              ? widget.textColor.withValues(alpha: 0.2)
                              : widget.backgroundColor,
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                          minimumSize: const Size(32, 32),
                        ),
                        icon: Stack(
                          children: [
                            Icon(
                              Icons.music_note,
                              color: isPlaying
                                  ? (Theme.of(context).colorScheme.primary)
                                  : widget.textColor,
                              size: 18,
                            ),
                            if (isPlaying)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  StreamBuilder<Map<String, String>>(
                    stream: _hymnService.getFavoriteStatusStream(),
                    builder: (context, snapshot) {
                      final favoriteStatus =
                          snapshot.data?[widget.hymn.id] ?? '';
                      final isFavorite = favoriteStatus.isNotEmpty;

                      return IconButton(
                        onPressed: widget.onFavoritePressed,
                        style: IconButton.styleFrom(
                          backgroundColor: widget.backgroundColor,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: const Size(32, 32),
                        ),
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? (favoriteStatus == 'cloud'
                                  ? Colors.red
                                  : Colors.blue)
                              : widget.textColor,
                          size: 18,
                        ),
                      );
                    },
                  ),
                  if (widget.isFirebaseHymn &&
                      isLoggedIn &&
                      (widget.hymn.createdByEmail == user.email || isAdmin))
                    IconButton(
                      onPressed: () => NavigationUtility.navigateToEditScreen(
                          context, widget.hymn),
                      style: IconButton.styleFrom(
                        backgroundColor: widget.backgroundColor,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        minimumSize: const Size(32, 32),
                      ),
                      icon:
                          Icon(Icons.edit, color: widget.textColor, size: 18),
                    ),
                  if (widget.isFirebaseHymn &&
                      isLoggedIn &&
                      (widget.hymn.createdByEmail == user.email || isAdmin))
                    IconButton(
                      onPressed: () => _showDeleteConfirmation(context),
                      style: IconButton.styleFrom(
                        backgroundColor: widget.backgroundColor,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        minimumSize: const Size(32, 32),
                      ),
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 18),
                    ),
                ],
              ),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              NavigationUtility.navigateToDetailScreen(context, widget.hymn);
            },
          ),
        ),
      ),
    );
  }
}
