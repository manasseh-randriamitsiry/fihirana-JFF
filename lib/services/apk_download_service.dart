import 'dart:io';

import 'dart:isolate';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../widgets/common/download_notification.dart';

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
      if (kDebugMode) {
        print('🚀 Starting APK download');
        print('📥 URL: $url');
        print('🏷️ Version: $version');
      }

      // Request storage and install permissions
      await _requestStoragePermission();
      final hasInstallPermission = await _requestInstallPermission();
      if (!hasInstallPermission) {
        await DownloadNotificationBuilder.showDownloadError(
          error: 'Tsy nahazo alalana hampiditra apk',
        );
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
      await DownloadNotificationBuilder.showDownloadStarted(progress: 0);

      // Start download in a separate isolate and wait for completion
      final downloadSuccess = await _startDownloadIsolate(url, savePath);

      if (downloadSuccess) {
        // Download completed successfully
        if (kDebugMode) {
          print('✅ Download completed at: ${DateTime.now()}');
        }
        await DownloadNotificationBuilder.showDownloadComplete(fileName: fileName);
      } else {
        // Download failed
        if (kDebugMode) {
          print('❌ Download failed');
        }
        await DownloadNotificationBuilder.showDownloadError();
        return;
      }

      // Install the APK
      await _installApk(savePath);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Download failed: $e');
      }
      await DownloadNotificationBuilder.showDownloadError(error: e.toString());
    }
  }

  static Future<bool> _startDownloadIsolate(String url, String savePath) async {
    final receivePort = ReceivePort();
    _receivePort = receivePort;

    final completer = Completer<bool>();

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
          DownloadNotificationBuilder.updateDownloadProgress(
              progress: message.percent);
        } else if (message is _DownloadError) {
          completer.complete(false);
          receivePort.close();
        } else if (message is _DownloadComplete) {
          completer.complete(true);
          receivePort.close();
        }
      });

      return await completer.future;
    } catch (e) {
      _downloadIsolate?.kill(priority: Isolate.immediate);
      return false;
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
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
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
        if (kDebugMode) {
          print('📂 File exists at: ${params.savePath}');
          print('⚠️ Deleting existing file for fresh download.');
        }
        // Delete existing file for fresh download
        try {
          await file.delete();
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ Error deleting existing file: $e');
          }
        }
      } else {
        if (kDebugMode) {
          print('📂 File does not exist at: ${params.savePath}');
        }
      }
// Don't create empty file beforehand - download directly to avoid empty files if download fails

      if (supportsRange) {
        await _downloadParallel(dio, params, contentLength);
      } else {
        await _downloadStandard(dio, params);
      }

      // Verify download completed successfully
      if (!await file.exists()) {
        throw Exception('Download failed: File does not exist after download');
      }

      final fileSize = await file.length();
      if (fileSize != contentLength) {
        throw Exception(
            'Download incomplete: Expected $contentLength bytes, got $fileSize bytes');
      }

      if (kDebugMode) {
        print('✅ Download verification passed: $fileSize bytes');
      }

      params.sendPort.send(_DownloadComplete());
    } catch (e) {
      params.sendPort.send(_DownloadError(e.toString()));
    }
  }

  static Future<void> _downloadParallel(
      Dio dio, _DownloadParams params, int contentLength) async {
    const int numChunks = 16; // Reduced chunks for better reliability
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
      ).catchError((e) {
        if (kDebugMode) {
          print('❌ Chunk $i download failed: $e');
        }
        throw Exception('Chunk $i download failed: $e');
      }));
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

    try {
      await Future.wait(futures);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Parallel download failed: $e');
      }
      rethrow;
    } finally {
      await progressSubscription.cancel();
      progressPort.close();
    }
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
      int chunkBytesDownloaded = 0;
      await for (final chunk in stream) {
        await raf.writeFrom(chunk);
        chunkBytesDownloaded += chunk.length;
        onProgress(chunk.length);
      }

      // Verify we got the expected amount of data for this chunk
      final expectedChunkSize = endByte - startByte + 1;
      if (chunkBytesDownloaded != expectedChunkSize) {
        if (kDebugMode) {
          print(
              '⚠️ Chunk size mismatch: expected $expectedChunkSize, got $chunkBytesDownloaded');
        }
        // Don't throw error here as it might be the last chunk which can be smaller
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Chunk download error ($startByte-$endByte): $e');
      }
      rethrow;
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
        String relativePath = 'Downloads/$fileName';

        if (filePath.contains('/storage/emulated/0/Download/')) {
          // File is in public Downloads directory
          pathName = 'external_storage';
          // Extract path relative to /storage/emulated/0/
          final parts = filePath.split('/storage/emulated/0/');
          if (parts.length > 1) {
            relativePath = parts[1];
          }
        } else if (filePath.contains('/Android/data/')) {
          // File is in app-specific external storage
          pathName = 'external_files';
          // For external_files, the root is .../files/
          // If our path is .../files/Downloads/file.apk, relative path is Downloads/file.apk
          if (filePath.contains('/files/')) {
            final parts = filePath.split('/files/');
            if (parts.length > 1) {
              relativePath = parts[1];
            }
          }
        }

        // Use file provider URI for installation
        final uri =
            'content://$packageName.fileprovider/$pathName/$relativePath';

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
      await DownloadNotificationBuilder.showInstallError(error: e.toString());
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

  static Future<void> handleDownloadAction(String action) async {
    if (action == 'CANCEL_DOWNLOAD') {
      cancelDownload();
      await DownloadNotificationBuilder.showCancelled();
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
