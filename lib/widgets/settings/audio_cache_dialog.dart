import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../services/audio_service.dart';
import '../../l10n/app_localizations.dart';

class AudioCacheDialog extends StatelessWidget {
  const AudioCacheDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final audioService = AudioService.instance;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: colorController.backgroundColor.value,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l10n.audioCacheManagement,
        style: TextStyle(
          color: colorController.textColor.value,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: FutureBuilder<Map<String, dynamic>>(
        future: audioService.getCacheStats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data!;
          final totalHymns = (stats['total_checked'] as int?) ?? 0;
          final withAudio = (stats['with_audio'] as int?) ?? 0;
          final withoutAudio = (stats['without_audio'] as int?) ?? 0;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.totalCachedHymns(totalHymns),
                style: TextStyle(color: colorController.textColor.value),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.withAudio(withAudio),
                style: TextStyle(
                    color: colorController.textColor.value
                        .withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.withoutAudio(withoutAudio),
                style: TextStyle(
                    color: colorController.textColor.value
                        .withValues(alpha: 0.8)),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel,
              style: TextStyle(color: colorController.textColor.value)),
        ),
        TextButton(
          onPressed: () async {
            await audioService.clearExpiredCache();
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.expiredCacheCleared)),
              );
            }
          },
          child: Text(l10n.clearExpired,
              style: TextStyle(color: colorController.primaryColor.value)),
        ),
        TextButton(
          onPressed: () async {
            await audioService.clearAllCache();
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.allCacheCleared)),
              );
            }
          },
          child:
              Text(l10n.clearAll, style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}