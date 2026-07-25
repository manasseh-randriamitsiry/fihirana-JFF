import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'notification_styles.dart';

class DownloadNotificationBuilder {
  static const int notificationId = 1001;

  static Future<void> showDownloadStarted({
    String title = 'Maka fanavaozana...',
    String body = '0%',
    int progress = 0,
    bool showCancelButton = true,
  }) async {
    final isNotificationAllowed =
        await AwesomeNotifications().isNotificationAllowed();
    if (!isNotificationAllowed) {
      return; // Don't show download notifications if disabled
    }

    final actionButtons = showCancelButton
        ? NotificationButtons.createDownloadButtons(
            cancelKey: 'CANCEL_DOWNLOAD')
        : null;

    final content = NotificationLayouts.createProgressBarNotification(
      id: notificationId,
      channelKey: 'hymn_download_channel',
      title: 'Fangalana fanavaozana',
      body: body,
      progress: progress.toDouble(),
      color: NotificationStyles.primaryColor,
      locked: true,
      autoDismissible: false,
      actionButtons: actionButtons,
    );

    await AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> updateDownloadProgress({
    required int progress,
    String title = 'Fangalana fanavaozana',
  }) async {
    final isNotificationAllowed =
        await AwesomeNotifications().isNotificationAllowed();
    if (!isNotificationAllowed) {
      return; // Don't show download notifications if disabled
    }

    final body = 'Fangalana... $progress%';

    final content = NotificationLayouts.createProgressBarNotification(
      id: notificationId,
      channelKey: 'hymn_download_channel',
      title: title,
      body: body,
      progress: progress.toDouble(),
      color: NotificationStyles.primaryColor,
      locked: true,
      autoDismissible: false,
      actionButtons: NotificationButtons.createDownloadButtons(
        cancelKey: 'CANCEL_DOWNLOAD',
        showCancel: progress < 100,
      ),
    );

    await AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> showDownloadComplete({
    required String fileName,
    String title = 'Vita ny fangalana',
  }) async {
    final isNotificationAllowed =
        await AwesomeNotifications().isNotificationAllowed();
    if (!isNotificationAllowed) {
      return; // Don't show download notifications if disabled
    }

    final content = NotificationLayouts.createSuccessNotification(
      id: notificationId,
      title: title,
      body: 'Voaray ny fanavaozana $fileName',
    );

    await AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> showDownloadError({
    String? error,
    String title = 'Tsy nety',
    String body = 'Nisy olana teo ampanavaozana',
  }) async {
    final isNotificationAllowed =
        await AwesomeNotifications().isNotificationAllowed();
    if (isNotificationAllowed) {
      final errorMessage = error != null ? '$body: $error' : body;

      final content = NotificationLayouts.createErrorNotification(
        id: notificationId + 1,
        title: title,
        body: errorMessage,
      );

      await AwesomeNotifications().createNotification(content: content);
    } else {
      // Show permission dialog instead of error notification
      await _showNotificationPermissionDialog();
    }
  }

  static Future<void> showInstallError({
    String? error,
    String title = 'Nisy olana',
    String body = 'Tsy afaka nametraka ny fanavaozana',
  }) async {
    final isNotificationAllowed =
        await AwesomeNotifications().isNotificationAllowed();
    if (isNotificationAllowed) {
      final errorMessage = error != null ? '$body: $error' : body;

      final content = NotificationLayouts.createErrorNotification(
        id: notificationId + 2,
        title: title,
        body: errorMessage,
      );

      await AwesomeNotifications().createNotification(content: content);
    } else {
      // Show permission dialog instead of error notification
      await _showNotificationPermissionDialog();
    }
  }

  static Future<void> showCancelled({
    String title = 'Ajanona',
    String body = 'Najanony ny fanavaozana',
  }) async {
    final isNotificationAllowed =
        await AwesomeNotifications().isNotificationAllowed();
    if (!isNotificationAllowed) {
      return; // Don't show download notifications if disabled
    }

    final content = NotificationLayouts.createBasicNotification(
      id: notificationId + 3,
      channelKey: 'hymn_download_channel',
      title: title,
      body: body,
      color: NotificationStyles.primaryColor,
    );

    await AwesomeNotifications().createNotification(content: content);
  }

  static Future<void> _showNotificationPermissionDialog() async {
    final context = Get.context;
    if (context == null) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions requises'),
          content: const Text(
              'Les notifications sont désactivées. Veuillez accorder la permission de notification pour recevoir les mises à jour de téléchargement.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Request notification permission
                final granted = await AwesomeNotifications()
                    .requestPermissionToSendNotifications();
                if (granted) {
                  // Show success message
                  Get.snackbar(
                    'Succès',
                    'Permission de notification accordée',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                }
              },
              child: const Text('Accorder la permission'),
            ),
          ],
        );
      },
    );
  }
}
