import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class AudioCacheDialog extends StatelessWidget {
  const AudioCacheDialog({super.key});

  // Method to show the audio cache dialog as a bottom sheet
  static void showAudioCacheDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const AudioCacheDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioService = AudioService.instance;
    final l10n = AppLocalizations.of(context);

    return GetBuilder<ColorController>(
      builder: (colorController) => Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: colorController.backgroundColor.value,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: colorController.primaryColor.value,
              width: 2,
            ),
            left: BorderSide(
              color: colorController.primaryColor.value,
              width: 2,
            ),
            right: BorderSide(
              color: colorController.primaryColor.value,
              width: 2,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorController.primaryColor.value.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.storage,
                    size: 28,
                    color: colorController.primaryColor.value,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.audioCacheManagement,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorController.textColor.value,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FutureBuilder<Map<String, dynamic>>(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.totalCachedHymns(totalHymns),
                          style: TextStyle(
                            color: colorController.textColor.value,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.withAudio(withAudio),
                          style: TextStyle(
                            color: colorController.textColor.value.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.withoutAudio(withoutAudio),
                          style: TextStyle(
                            color: colorController.textColor.value.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  l10n.cancel,
                                  style: TextStyle(
                                    color: colorController.textColor.value,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextButton(
                                onPressed: () async {
                                  await audioService.clearExpiredCache();
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(l10n.expiredCacheCleared)),
                                    );
                                  }
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  l10n.clearExpired,
                                  style: TextStyle(
                                    color: colorController.primaryColor.value,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextButton(
                                onPressed: () async {
                                  await audioService.clearAllCache();
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(l10n.allCacheCleared)),
                                    );
                                  }
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  l10n.clearAll,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
