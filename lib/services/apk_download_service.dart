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
  static const int downloadNotificationd = 1001;
  static Dio? _dio;
  static CancelToken? _cancelToken;

  static void _initializeDio() {
    _dio ??= Dio();
  }

  static Future<bool> _requestInstallPermission() async {
    if (Platform.isAndroid) {
      // Check if we can request install packages
      final status = await Permission.requestInstallPackages.status;
      if (!status.isGranted) {
        final result = await Permission.requestInstallPackages.request();
        return result.isGranted;
      }
      return true;
    }
    return true;
  }

  static Future<void> downloadAndInstallApk(String url, String version) async {
    try {
      _initializeDio();

      // Request install permission
      final hasPermission = await _requestInstallPermission();
      if (!hasPermission) {
        await _showNotification(
            'Tsy afaka naka', 'Tsy manana alalana ianao hampiditra apk');
        return;
      }

      // Get download directory - use external cache directory (no permission needed on Android 10+)
      Directory directory;
      if (Platform.isAndroid) {
        // Use external cache directory which doesn't require storage permissions
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Create a Downloads subfolder in the external cache
          directory = Directory('${externalDir.path}/Downloads');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        } else {
          // Fallback to app documents directory
          directory = await getApplicationDocumentsDirectory();
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
      await _showDownloadNotification('Maka fanavaozana...', 0);

      _cancelToken = CancelToken();

      // Download the file
      await _dio!.download(
        url,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = (received / total * 100).round();
            _showDownloadNotification('Fangalana... $progress%', progress);
          }
        },
      );

      // Download completed
      await _showNotification(
          'Vita ny fangalana', 'Voaray ny fanavaozana $fileName');

      // Install the APK
      await _installApk(savePath);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Download failed: $e');
      }
      await _showNotification('Tsy nety',
          'Nisy olana teo ampanaovana fanavaozana: ${e.toString()}');
    }
  }

  static Future<void> _installApk(String filePath) async {
    try {
      if (Platform.isAndroid) {
        final packageInfo = await PackageInfo.fromPlatform();
        final packageName = packageInfo.packageName;

        // Get the file name
        final file = File(filePath);
        final fileName = file.path.split('/').last;

        // Determine the correct path name based on file location
        String pathName = 'external_cache';
        if (filePath.contains('/Android/data/')) {
          // File is in external storage
          pathName = 'external_files';
        }

        // Use file provider URI for installation
        final uri =
            'content://$packageName.fileprovider/$pathName/Downloads/$fileName';

        if (kDebugMode) {
          print('📦 Installing APK from URI: $uri');
          print('📂 File path: $filePath');
        }

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
      await _showNotification(
          'Tsy nety', 'Tsy afaka mametraka ny fanavaozana: ${e.toString()}');
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
        id: downloadNotificationd,
        channelKey: 'hymn_download_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        color: const Color(0xFF9D50DD),
      ),
    );
  }

  static Future<void> _showDownloadNotification(
      String body, int progress) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: downloadNotificationd,
        channelKey: 'hymn_download_channel',
        title: 'Fangalana fanavaozana',
        body: body,
        notificationLayout: NotificationLayout.ProgressBar,
        progress: progress.toDouble(),
        locked: true,
        autoDismissible: false,
        color: const Color(0xFF9D50DD),
      ),
      actionButtons: progress < 100
          ? [
              NotificationActionButton(
                key: 'CANCEL_DOWNLOAD',
                label: 'Ajanona',
                actionType: ActionType.Default,
              ),
            ]
          : null,
    );
  }

  static Future<void> handleDownloadAction(String action) async {
    if (action == 'CANCEL_DOWNLOAD') {
      cancelDownload();
      await _showNotification('Ajanona', 'Najanony ny fanavaozana');
    }
  }
}
