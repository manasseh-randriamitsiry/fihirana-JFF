import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/daily_verse/di/daily_verse_di.dart';
import 'package:fihirana/features/daily_verse/presentation/controllers/daily_verse_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/utils/translation_service.dart';
import 'package:fihirana/core/localization/language_controller.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

class DailyVerseSettingsScreen extends StatelessWidget {
  DailyVerseSettingsScreen({super.key});

  final DailyVerseController controller = DailyVerseDI.dailyVerseController;

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: controller.notificationTime.value,
    );

    if (picked != null) {
      controller.updateNotificationTime(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return AppPageScaffold(
      title: l10n.dailyBibleVerse,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          AppSection(
            title: l10n.dailyInspiration,
            child: AppGroupedSurface(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: colors.primaryContainer,
                        foregroundColor: colors.onPrimaryContainer,
                        child: const Icon(Icons.auto_stories_rounded),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.dailyInspiration,
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 2),
                            Text(l10n.receiveVerseEveryDay,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AppSection(
            title: l10n.dailyBibleVerse,
            child: AppGroupedSurface(
              children: [
                Obx(
                  () => AppListRow(
                    icon: controller.isEnabled.value
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    title: l10n.enableDailyVerse,
                    subtitle: controller.isEnabled.value
                        ? l10n.youWillReceiveDailyNotifications
                        : l10n.turnOnToReceiveDailyVerses,
                    trailing: Switch(
                      value: controller.isEnabled.value,
                      onChanged: controller.toggleDailyVerse,
                    ),
                    onTap: () => controller
                        .toggleDailyVerse(!controller.isEnabled.value),
                  ),
                ),
                const AppGroupDivider(),
                Obx(
                  () => AnimatedOpacity(
                    opacity: controller.isEnabled.value ? 1 : .45,
                    duration: const Duration(milliseconds: 200),
                    child: AppListRow(
                      icon: Icons.schedule_rounded,
                      title: l10n.notificationTime,
                      subtitle:
                          controller.notificationTime.value.format(context),
                      onTap: controller.isEnabled.value
                          ? () => _selectTime(context)
                          : null,
                    ),
                  ),
                ),
                const AppGroupDivider(),
                Obx(
                  () => AppListRow(
                    icon: Icons.send_outlined,
                    title: l10n.sendTestNotification,
                    subtitle: controller.isEnabled.value
                        ? null
                        : l10n.turnOnToReceiveDailyVerses,
                    onTap: controller.isEnabled.value
                        ? () async {
                            await controller.sendTestNotification();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(l10n.testNotificationSent)),
                              );
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
          AppSection(
            title: l10n.todaysVerse,
            child: Obx(() {
              if (controller.isLoading.value) {
                return const AppGroupedSurface(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                );
              }

              final verse = controller.todaysVerse.value;
              if (verse == null) {
                return AppGroupedSurface(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        l10n.noVerseAvailable,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                );
              }

              return AppGroupedSurface(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.format_quote_rounded,
                                color: colors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                verse.reference,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(color: colors.primary),
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.viewTranslation,
                              icon: const Icon(Icons.translate_rounded),
                              onPressed: () =>
                                  _showTranslationDialog(context, verse.text),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            verse.text,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(height: 1.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _showTranslationDialog(BuildContext context, String text) async {
    final l10n = AppLocalizations.of(context);
    final languageController = Get.find<LanguageController>();

    // Determine target language
    String targetLang = languageController.currentLocale.value.languageCode;
    if (targetLang == 'mg') {
      targetLang = 'en';
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final translationService = TranslationService();

      // Check if model is downloaded
      final isDownloaded =
          await translationService.isModelDownloaded(targetLang);

      if (!isDownloaded) {
        if (context.mounted) {
          Navigator.pop(context); // Close loading

          final shouldDownload = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.download),
              content: Text(
                  'Mila maka ny modelin\'ny teny $targetLang aloha. Te hanohy ve ianao?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.download),
                ),
              ],
            ),
          );

          if (shouldDownload != true) return;

          if (context.mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            );
          }

          final success = await translationService.downloadModel(targetLang);
          if (!success) {
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.downloadFailed)),
              );
            }
            return;
          }
        }
      }

      // Translate text
      final translatedText = await translationService.translate(
        text: text,
        sourceLanguage: 'mg', // Assuming verse is in Malagasy
        targetLanguage: targetLang,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.viewTranslation,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Text(
                        translatedText,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(height: 1.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorOccurred)),
        );
      }
    }
  }
}
