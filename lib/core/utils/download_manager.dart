import 'notification_service.dart';

class DownloadManager {
  Future<void> initNotifications() async {
    await NotificationService.initializeNotificationChannels();
  }

  Future<void> downloadHymns({
    Function(double)? onProgress,
    Function(String)? onError,
  }) async {
    if (onProgress != null) {
      onProgress(1.0);
    }
  }

  Future<bool> checkForUpdates() async {
    return false;
  }
}
