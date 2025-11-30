import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/daily_verse_controller.dart';
import '../../controller/color_controller.dart';
import '../../l10n/app_localizations.dart';
import 'package:fihirana/services/core/translation_service.dart';
import '../../controller/language_controller.dart';

class DailyVerseSettingsScreen extends StatelessWidget {
  DailyVerseSettingsScreen({super.key});

  final DailyVerseController controller = Get.put(DailyVerseController());
  final ColorController colorController = Get.find<ColorController>();

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: controller.notificationTime.value,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colorController.primaryColor.value,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.updateNotificationTime(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorController.iconColor.value,
          ),
        ),
        title: Text(
          l10n.dailyBibleVerse,
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorController.primaryColor.value,
                    colorController.primaryColor.value.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_stories,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.dailyInspiration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.receiveVerseEveryDay,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Enable/Disable Toggle
            Card(
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: colorController.backgroundColor.value,
              child: Obx(() => SwitchListTile(
                    title: Text(
                      l10n.enableDailyVerse,
                      style: TextStyle(
                        color: colorController.textColor.value,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      controller.isEnabled.value
                          ? l10n.youWillReceiveDailyNotifications
                          : l10n.turnOnToReceiveDailyVerses,
                      style: TextStyle(
                        color: colorController.textColor.value
                            .withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    value: controller.isEnabled.value,
                    onChanged: (value) => controller.toggleDailyVerse(value),
                    activeThumbColor: colorController.primaryColor.value,
                    secondary: Icon(
                      controller.isEnabled.value
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: controller.isEnabled.value
                          ? colorController.primaryColor.value
                          : colorController.iconColor.value
                              .withValues(alpha: 0.5),
                    ),
                  )),
            ),
            const SizedBox(height: 16),

            // Notification Time
            Obx(() => AnimatedOpacity(
                  opacity: controller.isEnabled.value ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 300),
                  child: Card(
                    elevation: 2,
                    shadowColor: Colors.black.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: colorController.backgroundColor.value,
                    child: ListTile(
                      enabled: controller.isEnabled.value,
                      leading: Icon(
                        Icons.access_time,
                        color: controller.isEnabled.value
                            ? colorController.primaryColor.value
                            : colorController.iconColor.value
                                .withValues(alpha: 0.5),
                      ),
                      title: Text(
                        l10n.notificationTime,
                        style: TextStyle(
                          color: colorController.textColor.value,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        controller.notificationTime.value.format(context),
                        style: TextStyle(
                          color: colorController.textColor.value
                              .withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: colorController.iconColor.value,
                      ),
                      onTap: controller.isEnabled.value
                          ? () => _selectTime(context)
                          : null,
                    ),
                  ),
                )),
            const SizedBox(height: 24),

            // Today's Verse Preview
            Text(
              l10n.todaysVerse,
              style: TextStyle(
                color: colorController.textColor.value,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      color: colorController.primaryColor.value,
                    ),
                  ),
                );
              }

              final verse = controller.todaysVerse.value;
              if (verse == null) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: colorController.backgroundColor.value,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        l10n.noVerseAvailable,
                        style: TextStyle(
                          color: colorController.textColor.value
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Card(
                elevation: 4,
                shadowColor:
                    colorController.primaryColor.value.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorController.primaryColor.value
                        .withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                color: colorController.backgroundColor.value,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_quote,
                            color: colorController.primaryColor.value,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              verse.reference,
                              style: TextStyle(
                                color: colorController.primaryColor.value,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.translate,
                                color: colorController.iconColor.value),
                            onPressed: () =>
                                _showTranslationDialog(context, verse.text),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        verse.text,
                        style: TextStyle(
                          color: colorController.textColor.value,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Test Notification Button
            Obx(() => AnimatedOpacity(
                  opacity: controller.isEnabled.value ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 300),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: controller.isEnabled.value
                          ? () async {
                              await controller.sendTestNotification();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.testNotificationSent),
                                    backgroundColor:
                                        colorController.primaryColor.value,
                                  ),
                                );
                              }
                            }
                          : null,
                      icon: Icon(
                        Icons.send,
                        color: controller.isEnabled.value
                            ? colorController.primaryColor.value
                            : colorController.iconColor.value
                                .withValues(alpha: 0.5),
                      ),
                      label: Text(
                        l10n.sendTestNotification,
                        style: TextStyle(
                          color: controller.isEnabled.value
                              ? colorController.primaryColor.value
                              : colorController.textColor.value
                                  .withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: controller.isEnabled.value
                              ? colorController.primaryColor.value
                              : colorController.textColor.value
                                  .withValues(alpha: 0.2),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _showTranslationDialog(BuildContext context, String text) async {
    final l10n = AppLocalizations.of(context)!;
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
                color: Get.find<ColorController>().backgroundColor.value,
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
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Get.find<ColorController>().textColor.value,
                        ),
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
                        style: TextStyle(
                          fontSize: 18,
                          color: Get.find<ColorController>().textColor.value,
                          height: 1.6,
                        ),
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
