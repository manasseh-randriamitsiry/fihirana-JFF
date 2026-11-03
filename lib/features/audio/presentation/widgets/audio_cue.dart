import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/components/app_register_row.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/l10n/app_localizations.dart';

/// What a tap on a second hymn means while another one is already playing.
enum CueChoice { cancel, cue, playNow }

/// The existing translations have no word for a queue, so the dialog is made of
/// labels that do exist plus the two hymn names, which are data, not text.
Future<CueChoice> askCueOrPlay(BuildContext context,
    {required Hymn hymn}) async {
  final current = AudioService.instance.currentHymn;

  final choice = await showDialog<CueChoice>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext);
      final body = <Widget>[
        if (current != null) ...[
          Text(
            l10n.nowPlaying,
            style: Theme.of(dialogContext).textTheme.labelMedium,
          ),
          Text('${current.hymnNumber} ${current.title}'),
          const SizedBox(height: AppScale.space16),
        ],
        Text(
          '${hymn.hymnNumber} ${hymn.title}',
          style: Theme.of(dialogContext).textTheme.titleSmall,
        ),
      ];
      return AlertDialog(
        title: Text(l10n.playAudio),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: body,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(CueChoice.playNow),
            child: Text(l10n.play),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(CueChoice.cue),
            child: Text(l10n.next),
          ),
        ],
      );
    },
  );

  return choice ?? CueChoice.cancel;
}

/// Cue [hymn] and say so: nothing else on the screen changes, which is exactly
/// why the tap would otherwise look dead.
Future<void> cueHymn(BuildContext context, Hymn hymn) async {
  final l10n = AppLocalizations.of(context);
  final s = AppSurfaces.of(context);

  await AudioService.instance.addToCue(hymn);
  _confirmCued(l10n, s, hymn);
}

/// Ask, then act on the answer.
Future<void> playOrCueHymn(BuildContext context, Hymn hymn) async {
  final service = AudioService.instance;
  final l10n = AppLocalizations.of(context);
  final s = AppSurfaces.of(context);

  final choice = await askCueOrPlay(context, hymn: hymn);
  switch (choice) {
    case CueChoice.cue:
      await service.addToCue(hymn);
      _confirmCued(l10n, s, hymn);
    case CueChoice.playNow:
      await service.stopCurrentAndPlayNew(hymn);
    case CueChoice.cancel:
      break;
  }
}

/// The confirmation floats, because it is raised from inside the player sheet as
/// often as from a list, and a scaffold snackbar would sit behind it.
void _confirmCued(AppLocalizations l10n, AppSurfaces s, Hymn hymn) {
  Get.snackbar(
    l10n.next,
    '${hymn.hymnNumber} ${hymn.title}',
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: s.accent,
    colorText: s.onAccent,
    margin: const EdgeInsets.all(AppScale.space16),
    borderRadius: AppScale.radiusControl,
  );
}

/// The hymns waiting after the one that is playing, with whatever actions the
/// host puts beside the heading (clear, add). It draws nothing while the cue is
/// empty, so a player can hold it unconditionally.
class AudioCueList extends StatelessWidget {
  const AudioCueList({
    super.key,
    this.actions = const [],
    this.trailing,
    this.onPlayNow,
  });

  final List<Widget> actions;

  /// A rule or a spacer that closes the block; drawn only when there is a cue.
  final Widget? trailing;

  /// Called after the hymn has left the queue, so the host can start it.
  final void Function(Hymn hymn)? onPlayNow;

  @override
  Widget build(BuildContext context) {
    final service = AudioService.instance;
    final l10n = AppLocalizations.of(context);

    return Obx(() {
      final cue = service.cueRx;
      if (cue.isEmpty) return const SizedBox.shrink();

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppScale.gutter,
                AppScale.space12, AppScale.space12, AppScale.space4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.next,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...actions,
              ],
            ),
          ),
          ListView.separated(
            key: const PageStorageKey('audio_cue_list'),
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(AppScale.gutter, AppScale.space4,
                AppScale.gutter, AppScale.space8),
            itemCount: cue.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppScale.space4),
            itemBuilder: (context, index) {
              final hymn = cue[index];
              return AppRegisterRow(
                key: ValueKey('cue_${hymn.id}_$index'),
                figure: hymn.hymnNumber,
                title: hymn.title,
                // Tap plays it now, which also takes it out of the cue.
                onTap: () {
                  service.removeCuedAt(index);
                  onPlayNow?.call(hymn);
                },
                trailing: IconButton(
                  tooltip: l10n.remove,
                  icon: const Icon(Icons.close_rounded, size: AppScale.iconMd),
                  onPressed: () => service.removeCuedAt(index),
                ),
              );
            },
          ),
        ],
      );
    });
  }
}
