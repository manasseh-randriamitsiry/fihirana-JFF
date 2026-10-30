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
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/components/app_register_row.dart';

/// A line of the register: the number, the name, the first line, and whatever
/// the row can do.
class HymnListItem extends StatefulWidget {
  final Hymn hymn;
  final VoidCallback onFavoritePressed;
  final VoidCallback? onMusicPressed;
  final bool isFirebaseHymn;
  final bool hasAudio;
  final bool isFavorite;

  const HymnListItem({
    super.key,
    required this.hymn,
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
        return StatefulBuilder(
          builder: (context, setState) {
            void reject() {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text(context.translate((l) => l.typeYesToConfirm))),
              );
            }

            void accept(String value) {
              if (value.toLowerCase() == 'eny' ||
                  value.toLowerCase() == 'oui' ||
                  value.toLowerCase() == 'yes') {
                isConfirmed = true;
                Navigator.of(context).pop();
              } else {
                reject();
              }
            }

            return AlertDialog(
              title: Text(context.translate((l) => l.deleteHymnQuestion)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.translate(
                      (l) => l.confirmDeleteHymn(widget.hymn.title))),
                  const SizedBox(height: AppScale.space16),
                  TextField(
                    controller: confirmationController,
                    onSubmitted: accept,
                    decoration: InputDecoration(
                      hintText: context.translate((l) => l.yesLowercase),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(context.translate((l) => l.cancel)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(context.translate((l) => l.delete),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                  onPressed: () => accept(confirmationController.text),
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
        final Color error = Theme.of(context).colorScheme.error;
        return AlertDialog(
          title: Text(context.translate((l) => l.deleteHymnQuestion)),
          content: Text(
              context.translate((l) => l.confirmDeleteHymn(widget.hymn.title))),
          actions: <Widget>[
            TextButton(
              child: Text(context.translate((l) => l.no)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(context.translate((l) => l.yes),
                  style: TextStyle(color: error)),
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
                      SnackBar(content: Text(deleteHymnFailedMessage)),
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
                      SnackBar(content: Text(hymnDeletedSuccessMessage)),
                    );
                  }
                } catch (e) {
                  // Check if widget is still mounted before showing error
                  if (!mounted) return;

                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('$errorMessage: $e')),
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
          SnackBar(content: Text(errorMessage)),
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

    final AppSurfaces s = AppSurfaces.of(context);
    final bool isPlaying = _audioService.isHymnPlaying(widget.hymn.id);

    return Semantics(
      button: true,
      label: '${widget.hymn.hymnNumber} ${widget.hymn.title}',
      child: AppRegisterRow(
        figure: widget.hymn.hymnNumber,
        selected: isPlaying,
        onTap: () =>
            NavigationUtility.navigateToDetailScreen(context, widget.hymn),
        title: widget.hymn.title,
        subtitle: widget.hymn.verses.isNotEmpty ? widget.hymn.verses[0] : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isFavorite)
              _RowAction(
                icon: Icons.favorite_rounded,
                tooltip: AppLocalizations.of(context).favoriteHymns,
                color: s.accent,
                onPressed: widget.onFavoritePressed,
              )
            else
              _RowAction(
                icon: Icons.favorite_border_rounded,
                tooltip: AppLocalizations.of(context).favoriteHymns,
                onPressed: widget.onFavoritePressed,
              ),
            if (widget.hasAudio)
              Obx(() {
                final playing = _audioService.isHymnPlaying(widget.hymn.id);
                return _RowAction(
                  icon: playing
                      ? Icons.graphic_eq_rounded
                      : Icons.music_note_rounded,
                  tooltip: AppLocalizations.of(context).playAudio,
                  color: playing ? s.accent : null,
                  onPressed:
                      widget.onMusicPressed ?? () => _playHymnAudio(context),
                );
              }),
            if (widget.isFirebaseHymn &&
                isLoggedIn &&
                (widget.hymn.createdByEmail == user.email || isAdmin))
              PopupMenuButton<String>(
                icon:
                    const Icon(Icons.more_vert_rounded, size: AppScale.iconMd),
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
                        const Icon(Icons.edit_rounded, size: AppScale.iconMd),
                        const SizedBox(width: AppScale.space12),
                        Text(AppLocalizations.of(context).edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded,
                            color: Theme.of(context).colorScheme.error,
                            size: AppScale.iconMd),
                        const SizedBox(width: AppScale.space12),
                        Text(AppLocalizations.of(context).delete,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// A control in a register row: 44px to the finger, quiet to the eye.
class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Widget button = IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: AppScale.iconMd, color: color),
      style: IconButton.styleFrom(
        minimumSize: const Size(AppScale.hitTarget, AppScale.hitTarget),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
