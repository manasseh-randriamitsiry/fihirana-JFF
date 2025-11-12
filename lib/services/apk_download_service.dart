import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ApkDownloadService {
  static const int DOWNLOAD_NOTIFICATION_ID = 1001;
  static Dio? _dio;
  static CancelToken? _cancelToken;

  static void _initializeDio() {
    _dio ??= Dio();
  }

  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      final status2 = await Permission.manageExternalStorage.request();
      return status.isGranted || status2.isGranted;
    }
    return true;
  }

  static Future<void> downloadAndInstallApk(String url, String version) async {
    try {
      _initializeDio();
      
      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        await _showNotification('Tsy afaka mankafy', 'Tsy manana alalana ianao hampidirana rakitra');
        return;
      }

      // Get download directory
      Directory directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final fileName = 'fihirana-v$version.apk';
      final savePath = '${directory.path}/$fileName';

      if (kDebugMode) {
        print('📥 Downloading APK to: $savePath');
      }

      // Show download started notification
      await _showDownloadNotification('Mandefa anaty rakitra...', 0);

      _cancelToken = CancelToken();
      
      // Download the file
      await _dio!.download(
        url,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).round();
            _showDownloadNotification('Mandefa anaty rakitra... $progress%', progress);
          }
        },
      );

      // Download completed
      await _showNotification('Vita ny fandefasana', 'Voara ny rakitra $fileName');

      // Install the APK
      await _installApk(savePath);

    } catch (e) {
      if (kDebugMode) {
        print('❌ Download failed: $e');
      }
      await _showNotification('Tsy voafafa', 'Tsy afaka mandefa anaty rakitra: ${e.toString()}');
    }
  }

  static Future<void> _installApk(String filePath) async {
    try {
      if (Platform.isAndroid) {
        final packageInfo = await PackageInfo.fromPlatform();
        final packageName = packageInfo.packageName;
        
        // Use file provider URI for installation
        final file = File(filePath);
        final uri = 'content://${packageName}.fileprovider/external_files/${file.path.split('/').last}';
        
        final intent = AndroidIntent(
          action: 'android.intent.action.INSTALL_PACKAGE',
          data: uri,
          type: 'application/vnd.android.package-archive',
          flags: <int>[
            268435456, // FLAG_GRANT_READ_URI_PERMISSION
            1, // FLAG_ACTIVITY_NEW_TASK
          ],
        );
        await intent.launch();
      } else {
        // For non-Android platforms, just open the file
        final result = await OpenFile.open(filePath);
        if (result.type != ResultType.done) {
          throw Exception('Failed to open file: ${result.message}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Install failed: $e');
      }
      await _showNotification('Tsy voafafa', 'Tsy afaka mametraka ny rindrambaiko: ${e.toString()}');
    }
  }

  static void cancelDownload() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('Download cancelled by user');
    }
  }

  static Future<void> _showNotification(String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DOWNLOAD_NOTIFICATION_ID,
        channelKey: 'hymn_download_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFF9D50DD),
      ),
    );
  }

  static Future<void> _showDownloadNotification(String body, int progress) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DOWNLOAD_NOTIFICATION_ID,
        channelKey: 'hymn_download_channel',
        title: 'Fandefasana rindrambaiko',
        body: body,
        notificationLayout: NotificationLayout.ProgressBar,
        progress: progress.toDouble(),
        locked: true,
        autoDismissible: false,
        color: const Color(0xFF9D50DD),
      ),
      actionButtons: progress < 100 ? [
        NotificationActionButton(
          key: 'CANCEL_DOWNLOAD',
          label: 'Ajanony',
          actionType: ActionType.Default,
        ),
      ] : null,
    );
  }

  static Future<void> handleDownloadAction(String action) async {
    if (action == 'CANCEL_DOWNLOAD') {
      cancelDownload();
      await _showNotification('Ajanony', 'Najanony ny fandefasana');
    }
  }
}