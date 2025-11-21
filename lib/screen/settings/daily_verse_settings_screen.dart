import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/daily_verse_controller.dart';
import '../../controller/color_controller.dart';

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
          'Daily Bible Verse',
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
                    colorController.primaryColor.value.withOpacity(0.7),
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
                      color: Colors.white.withOpacity(0.2),
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
                        const Text(
                          'Daily Inspiration',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Receive a Bible verse every day',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
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
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: colorController.backgroundColor.value,
              child: Obx(() => SwitchListTile(
                    title: Text(
                      'Enable Daily Verse',
                      style: TextStyle(
                        color: colorController.textColor.value,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      controller.isEnabled.value
                          ? 'You will receive daily notifications'
                          : 'Turn on to receive daily verses',
                      style: TextStyle(
                        color: colorController.textColor.value.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    value: controller.isEnabled.value,
                    onChanged: (value) => controller.toggleDailyVerse(value),
                    activeColor: colorController.primaryColor.value,
                    secondary: Icon(
                      controller.isEnabled.value
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: controller.isEnabled.value
                          ? colorController.primaryColor.value
                          : colorController.iconColor.value.withOpacity(0.5),
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
                    shadowColor: Colors.black.withOpacity(0.1),
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
                            : colorController.iconColor.value.withOpacity(0.5),
                      ),
                      title: Text(
                        'Notification Time',
                        style: TextStyle(
                          color: colorController.textColor.value,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        controller.notificationTime.value.format(context),
                        style: TextStyle(
                          color:
                              colorController.textColor.value.withOpacity(0.6),
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
              'Today\'s Verse',
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
                        'No verse available',
                        style: TextStyle(
                          color:
                              colorController.textColor.value.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Card(
                elevation: 4,
                shadowColor:
                    colorController.primaryColor.value.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: colorController.primaryColor.value.withOpacity(0.2),
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
                                    content:
                                        const Text('Test notification sent!'),
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
                            : colorController.iconColor.value.withOpacity(0.5),
                      ),
                      label: Text(
                        'Send Test Notification',
                        style: TextStyle(
                          color: controller.isEnabled.value
                              ? colorController.primaryColor.value
                              : colorController.textColor.value
                                  .withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: controller.isEnabled.value
                              ? colorController.primaryColor.value
                              : colorController.textColor.value
                                  .withOpacity(0.2),
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
}
