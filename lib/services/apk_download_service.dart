import 'dart:io';

import 'dart:ui';
import 'dart:isolate';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ApkDownloadService {
  static const int downloadNotificationd = 1001;
  // Keep track of the isolate to kill it if needed
  static Isolate? _downloadIsolate;
  static ReceivePort? _receivePort;

  static Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Request storage permissions for Android 10 and below
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        return result.isGranted;
      }
      return true;
    }
    return true;
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
      // Request storage and install permissions
      final hasStoragePermission = await _requestStoragePermission();
      final hasInstallPermission = await _requestInstallPermission();
      if (!hasInstallPermission) {
        await _showNotification(
            'Nisy olana', 'Tsy nahazo alalana hampiditra apk');
        return;
      }

      // Get download directory - use Downloads directory for better performance
      Directory directory;
      if (Platform.isAndroid) {
        // Try to use the public Downloads directory first (much faster I/O)
        try {
          final downloadsDir = Directory('/storage/emulated/0/Download');
          if (await downloadsDir.exists()) {
            directory = Directory('${downloadsDir.path}/Fihirana');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          } else {
            // Fallback to external cache directory
            final externalDir = await getExternalStorageDirectory();
            if (externalDir != null) {
              directory = Directory('${externalDir.path}/Downloads');
              if (!await directory.exists()) {
                await directory.create(recursive: true);
              }
            } else {
              directory = await getApplicationDocumentsDirectory();
            }
          }
        } catch (e) {
          // Fallback to external cache directory if permissions fail
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            directory = Directory('${externalDir.path}/Downloads');
            if (!await directory.exists()) {
              await directory.create(recursive: true);
            }
          } else {
            directory = await getApplicationDocumentsDirectory();
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final fileName = 'fihirana-v$version.apk';
      final savePath = '${directory.path}/$fileName';

      if (kDebugMode) {
        print('📥 Downloading APK to: $savePath');
        print('🌐 Download URL: $url');
        print('⏱️ Starting download at: ${DateTime.now()}');
      }

      // Show download started notification
      await _showDownloadNotification('Maka fanavaozana...', 0);

      // Start download in a separate isolate
      await _startDownloadIsolate(url, savePath);

      // Download completed
      if (kDebugMode) {
        print('✅ Download completed at: ${DateTime.now()}');
      }
      await _showNotification(
          'Vita ny fangalana', 'Voaray ny fanavaozana $fileName');

      // Install the APK
      await _installApk(savePath);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Download failed: $e');
      }
      await _showNotification(
          'Tsy nety', 'Nisy olana teo ampanavaozana: ${e.toString()}');
    }
  }

  static Future<void> _startDownloadIsolate(String url, String savePath) async {
    final receivePort = ReceivePort();
    _receivePort = receivePort;

    final completer = Completer<void>();

    try {
      _downloadIsolate = await Isolate.spawn(
        _isolateDownloadEntryPoint,
        _DownloadParams(
          url: url,
          savePath: savePath,
          sendPort: receivePort.sendPort,
        ),
      );

      receivePort.listen((message) {
        if (message is _DownloadProgress) {
          _showDownloadNotification(
              'Fangalana... ${message.percent}%', message.percent);
        } else if (message is _DownloadError) {
          completer.completeError(message.error);
          receivePort.close();
        } else if (message is _DownloadComplete) {
          completer.complete();
          receivePort.close();
        }
      });

      await completer.future;
    } catch (e) {
      _downloadIsolate?.kill(priority: Isolate.immediate);
      rethrow;
    } finally {
      _downloadIsolate = null;
      _receivePort = null;
    }
  }

  // Entry point for the isolate
  static Future<void> _isolateDownloadEntryPoint(_DownloadParams params) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 10),
        sendTimeout: const Duration(minutes: 5),
        headers: {
          'Connection': 'keep-alive',
          'Accept-Encoding': 'gzip, deflate, br',
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
        },
      ),
    );

    // Configure adapter
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.badCertificateCallback = (cert, host, port) => false;
      client.maxConnectionsPerHost = 16;
      return client;
    };

    try {
      // 1. Get file size
      final headResponse = await dio.head(params.url);
      final contentLength =
          int.tryParse(headResponse.headers.value('content-length') ?? '0') ??
              0;

      if (contentLength == 0) {
        throw Exception('Unable to determine file size');
      }

      final supportsRange =
          headResponse.headers.value('accept-ranges') == 'bytes';

      // Prepare the file
      final file = File(params.savePath);
      if (await file.exists()) {
        await file.delete();
      }
      // Create empty file with specific size to reserve space and avoid fragmentation
      final raf = await file.open(mode: FileMode.write);
      await raf.truncate(contentLength);
      await raf.close();

      if (supportsRange) {
        await _downloadParallel(dio, params, contentLength);
      } else {
        await _downloadStandard(dio, params);
      }

      params.sendPort.send(_DownloadComplete());
    } catch (e) {
      params.sendPort.send(_DownloadError(e.toString()));
    }
  }

  static Future<void> _downloadParallel(
      Dio dio, _DownloadParams params, int contentLength) async {
    const int numChunks = 8; // Increased chunks for better speed
    final int chunkSize = (contentLength / numChunks).ceil();
    final List<Future<void>> futures = [];

    // Shared progress tracking
    int totalDownloaded = 0;
    final progressPort = ReceivePort();

    // We need to use a separate RandomAccessFile for each chunk to avoid locking issues
    // or race conditions if the OS doesn't support concurrent writes to the same fd well.
    // However, Dart's RandomAccessFile is an object wrapping a file descriptor.
    // Opening multiple handles to the same file is generally safe for writing to different regions.

    for (int i = 0; i < numChunks; i++) {
      final int startByte = i * chunkSize;
      final int endByte = (i == numChunks - 1)
          ? contentLength - 1
          : (startByte + chunkSize - 1);

      futures.add(_downloadChunk(
        dio: dio,
        url: params.url,
        savePath: params.savePath,
        startByte: startByte,
        endByte: endByte,
        onProgress: (bytes) {
          progressPort.sendPort.send(bytes);
        },
      ));
    }

    // Monitor progress
    int lastPercent = 0;
    final progressSubscription = progressPort.listen((bytes) {
      totalDownloaded += (bytes as int);
      final percent = (totalDownloaded / contentLength * 100).round();
      if (percent > lastPercent) {
        lastPercent = percent;
        params.sendPort.send(_DownloadProgress(percent));
      }
    });

    await Future.wait(futures);
    await progressSubscription.cancel();
    progressPort.close();
  }

  static Future<void> _downloadChunk({
    required Dio dio,
    required String url,
    required String savePath,
    required int startByte,
    required int endByte,
    required Function(int) onProgress,
  }) async {
    // Open a dedicated handle for this chunk
    final file = File(savePath);
    final raf = await file.open(mode: FileMode.write);

    try {
      await raf.setPosition(startByte);

      final response = await dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Range': 'bytes=$startByte-$endByte',
          },
        ),
      );

      final stream = response.data!.stream;
      await for (final chunk in stream) {
        await raf.writeFrom(chunk);
        onProgress(chunk.length);
      }
    } finally {
      await raf.close();
    }
  }

  static Future<void> _downloadStandard(Dio dio, _DownloadParams params) async {
    await dio.download(
      params.url,
      params.savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final percent = (received / total * 100).round();
          params.sendPort.send(_DownloadProgress(percent));
        }
      },
    );
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
        if (filePath.contains('/storage/emulated/0/Download/') ||
            filePath.contains('/Android/data/')) {
          // File is in external storage or public Downloads
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
          'Nisy olana', 'Tsy afaka nametraka ny fanavaozana: ${e.toString()}');
    }
  }

  static void cancelDownload() {
    if (_downloadIsolate != null) {
      _downloadIsolate!.kill(priority: Isolate.immediate);
      _downloadIsolate = null;
      _receivePort?.close();
      _receivePort = null;
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

// Helper classes for Isolate communication
class _DownloadParams {
  final String url;
  final String savePath;
  final SendPort sendPort;

  _DownloadParams({
    required this.url,
    required this.savePath,
    required this.sendPort,
  });
}

class _DownloadProgress {
  final int percent;
  _DownloadProgress(this.percent);
}

class _DownloadError {
  final String error;
  _DownloadError(this.error);
}

class _DownloadComplete {}
