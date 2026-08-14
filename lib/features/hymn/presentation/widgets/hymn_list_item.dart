import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

class HymnListItem extends StatefulWidget {
  final Hymn hymn;
  final Color textColor;
  final Color backgroundColor;
  final Color primaryColor;
  final VoidCallback onFavoritePressed;
  final VoidCallback? onMusicPressed;
  final bool isFirebaseHymn;
  final bool hasAudio;
  final bool isFavorite;

  const HymnListItem({
    super.key,
    required this.hymn,
    required this.textColor,
    required this.backgroundColor,
    required this.primaryColor,
    required this.onFavoritePressed,
    this.onMusicPressed,
    this.isFirebaseHymn = false,
    this.hasAudio = false,
    this.isFavorite = false,
  });

  @override
  State<HymnListItem> createState() => _HymnListItemState();
}

class _HymnListItemState extends State<HymnListItem> {
  final HymnService _hymnService = HymnService();
  final AudioService _audioService = AudioService.instance;

  Future<bool> _confirmDeletion(BuildContext context) async {
    final confirmationController = TextEditingController();
    bool isConfirmed = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final colors = Theme.of(context).colorScheme;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colors.surface,
              title: Text(
                context.translate((l) => l.deleteHymnQuestion),
                style: TextStyle(color: colors.onSurface),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.translate(
                        (l) => l.confirmDeleteHymn(widget.hymn.title)),
                    style: TextStyle(color: colors.onSurface),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmationController,
                    style: TextStyle(color: colors.onSurface),
                    decoration: InputDecoration(
                      hintText: context.translate((l) => l.yesLowercase),
                      hintStyle: TextStyle(color: colors.onSurfaceVariant),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                        borderSide: BorderSide(color: colors.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
                        borderSide: BorderSide(color: colors.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSm),
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
                              context.translate((l) => l.typeYesToConfirm),
                              style: TextStyle(color: colors.onError),
                            ),
                            backgroundColor: colors.error,
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
                      style: TextStyle(color: colors.onSurface)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(context.translate((l) => l.delete),
                      style: TextStyle(color: colors.error)),
                  onPressed: () {
                    if (confirmationController.text.toLowerCase() == 'eny') {
                      isConfirmed = true;
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.translate((l) => l.typeYesToConfirm),
                            style: TextStyle(color: colors.onError),
                          ),
                          backgroundColor: colors.error,
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
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor: colors.surface,
          title: Text(context.translate((l) => l.deleteHymnQuestion),
              style: TextStyle(color: colors.onSurface)),
          content: Text(
            context.translate((l) => l.confirmDeleteHymn(widget.hymn.title)),
            style: TextStyle(color: colors.onSurface),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(context.translate((l) => l.no),
                  style: TextStyle(color: colors.onSurface)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(context.translate((l) => l.yes),
                  style: TextStyle(color: colors.error)),
              onPressed: () async {
                // Capture the context and localized messages before any async operations
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final deleteHymnFailedMessage =
                    context.translate((l) => l.deleteHymnFailed);
                final hymnDeletedSuccessMessage =
                    context.translate((l) => l.hymnDeletedSuccess);
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
                        backgroundColor: colors.error,
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
                        backgroundColor: colors.primary,
                      ),
                    );
                  }
                } catch (e) {
                  // Check if widget is still mounted before showing error
                  if (!mounted) return;

                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('$errorMessage: $e'),
                      backgroundColor: colors.error,
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
    final colors = Theme.of(context).colorScheme;

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
            backgroundColor: colors.error,
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

    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final primaryColor = colors.primary;
    final backgroundColor = colors.surface;
    final textColor = colors.onSurface;
    final pastelColor = Color.alphaBlend(
      primaryColor.withValues(alpha: 0.05),
      backgroundColor,
    );

    return Semantics(
      button: true,
      label: '${widget.hymn.hymnNumber} ${widget.hymn.title}',
      child: Material(
        color: pastelColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          onTap: () =>
              NavigationUtility.navigateToDetailScreen(context, widget.hymn),
          child: Padding(
            padding: const EdgeInsets.all(14),
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
                      color: primaryColor.withValues(
                          alpha: 0.1), // Consistent accent/primary container
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
                            color: colors.onSurfaceVariant,
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
                              color: colors.onSurfaceVariant,
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
                    if (widget.hasAudio)
                      Obx(() {
                        final isPlaying =
                            _audioService.isHymnPlaying(widget.hymn.id);
                        return IconButton(
                          onPressed: widget.onMusicPressed ??
                              () => _playHymnAudio(context),
                          icon: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isPlaying
                                  ? primaryColor.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.graphic_eq
                                  : Icons.music_note_outlined,
                              size: 20,
                              color: isPlaying
                                  ? primaryColor
                                  : colors.onSurfaceVariant,
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
                    IconButton(
                      onPressed: widget.onFavoritePressed,
                      icon: Icon(
                        widget.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: widget.isFavorite
                            ? colors.error
                            : colors.onSurfaceVariant,
                        size: 22,
                      ),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),

                    // Admin Actions Menu
                    if (widget.isFirebaseHymn &&
                        isLoggedIn &&
                        (widget.hymn.createdByEmail == user.email || isAdmin))
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded,
                            color: colors.onSurfaceVariant, size: 20),
                        onSelected: (value) {
                          if (value == 'edit') {
                            NavigationUtility.navigateToEditScreen(
                                context, widget.hymn);
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
                                Icon(Icons.delete_rounded,
                                    color: colors.error, size: 20),
                                const SizedBox(width: 12),
                                Text(AppLocalizations.of(context).delete,
                                    style: TextStyle(color: colors.error)),
                              ],
                            ),
                          ),
                        ],
                        color: backgroundColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
