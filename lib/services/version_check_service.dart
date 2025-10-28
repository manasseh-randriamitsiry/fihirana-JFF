import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:in_app_update/in_app_update.dart';

class VersionCheckService {
  static const String GITHUB_API_URL =
      'https://api.github.com/repos/manasseh-randriamitsiry/hymns_jff/releases/latest';
  static const String LAST_CHECK_KEY = 'last_version_check';
  static const Duration CHECK_INTERVAL = Duration(hours: 1);
  static const int UPDATE_NOTIFICATION_ID = 1;
  static Timer? _notificationTimer;
  static String? _cachedDownloadUrl;
  static String? _cachedVersion;
  static String? _cachedReleaseNotes;
  static AppUpdateInfo? _updateInfo;
  static bool _flexibleUpdateAvailable = false;
  static VoidCallback? _onUpdateAvailable;
  static VoidCallback? _onFlexibleUpdateDownloaded;

  static void setOnUpdateAvailableCallback(VoidCallback callback) {
    _onUpdateAvailable = callback;
  }

  static void setOnFlexibleUpdateDownloadedCallback(VoidCallback callback) {
    _onFlexibleUpdateDownloaded = callback;
  }

  static Future<void> initializeNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
        ),
      ],
      debug: true,
    );

    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    initializeActionListeners();

    startPeriodicCheck();
  }

  static void startPeriodicCheck() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(CHECK_INTERVAL, (timer) {
      checkForUpdate();
    });
  }

  static void stopPeriodicCheck() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  static Future<void> checkForUpdate() async {
    try {

      final updateInfo = await InAppUpdate.checkForUpdate();
      _updateInfo = updateInfo;

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {

        _onUpdateAvailable?.call();

        if (updateInfo.updatePriority >= 4) {
          await _performImmediateUpdate();
        } else {

          await _showInAppUpdateNotification();
        }
      } else {
        stopPeriodicCheck();
      }
    } catch (e) {

      await _checkForUpdateFromGitHub();
    }
  }

  static Future<void> _showInAppUpdateNotification() async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: UPDATE_NOTIFICATION_ID,
        channelKey: 'basic_channel',
        title: 'Misy rindrambaiko vaovao',
        body: 'Version vaovao dia efa azo ampiasaina! Tsindrio haka azy.',
        payload: {'type': 'in_app_update'},
        color: const Color(0xFF9D50DD),
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'UPDATE',
          label: 'Haka',
        ),
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Mbola tsy izao aloha',
          actionType: ActionType.Default,
        ),
      ],
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyPressed == 'UPDATE') {
      final type = receivedAction.payload?['type'];
      if (type == 'in_app_update' && _updateInfo != null) {

        if (_flexibleUpdateAvailable) {

          await _completeFlexibleUpdate();
        } else {

          await _performImmediateUpdate();
        }
        stopPeriodicCheck();
      } else if (_cachedDownloadUrl != null) {

        await _downloadAndInstallUpdate(_cachedDownloadUrl!);
        stopPeriodicCheck();
      }
    } else if (receivedAction.buttonKeyPressed == 'DISMISS') {
      stopPeriodicCheck();
    }
  }

  static Future<void> _performImmediateUpdate() async {
    try {
      if (_updateInfo?.updateAvailability == UpdateAvailability.updateAvailable) {
        final result = await InAppUpdate.performImmediateUpdate();

        if (result == AppUpdateResult.userDeniedUpdate) {
        } else if (result == AppUpdateResult.inAppUpdateFailed) {

          if (_cachedDownloadUrl != null) {
            await _downloadAndInstallUpdate(_cachedDownloadUrl!);
          }
        } else if (result == AppUpdateResult.success) {
        }
      }
    } catch (e) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: UPDATE_NOTIFICATION_ID + 1,
          channelKey: 'basic_channel',
          title: 'Tsy afaka nalaina',
          body:
              'Tsy afaka nalaina ny rindrambaiko vaovao. Avereno afaka kelikely azafady.',
          color: const Color(0xFF9D50DD),
        ),
      );
    }
  }

  static Future<void> startFlexibleUpdate() async {
    try {
      if (_updateInfo?.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        _flexibleUpdateAvailable = true;

        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: UPDATE_NOTIFICATION_ID + 2,
            channelKey: 'basic_channel',
            title: 'Fakàna rindrambaiko',
            body: 'Ny rindrambaiko vaovao dia amim-pakàna. Hahazo fampahalalam-baovao ianao rehefa vita ny fakàna.',
            payload: {'type': 'flexible_update_complete'},
            color: const Color(0xFF9D50DD),
          ),
        );
      }
    } catch (e) {
    }
  }

  static Future<void> _completeFlexibleUpdate() async {
    try {
      if (_flexibleUpdateAvailable) {
        await InAppUpdate.completeFlexibleUpdate();
        _flexibleUpdateAvailable = false;
      }
    } catch (e) {
    }
  }

  static Future<bool> checkForUpdateManually() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      _updateInfo = updateInfo;

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {

        _onUpdateAvailable?.call();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<void> triggerImmediateUpdate() async {
    if (_updateInfo?.updateAvailability == UpdateAvailability.updateAvailable) {
      await _performImmediateUpdate();
    }
  }

  static Future<void> triggerFlexibleUpdate() async {
    if (_updateInfo?.updateAvailability == UpdateAvailability.updateAvailable) {
      await startFlexibleUpdate();
    }
  }

  static Future<void> completeFlexibleUpdate() async {
    if (_flexibleUpdateAvailable) {
      await _completeFlexibleUpdate();

      _onFlexibleUpdateDownloaded?.call();
    }
  }

  static bool isFlexibleUpdateAvailable() {
    return _flexibleUpdateAvailable;
  }

  static Future<void> _checkForUpdateFromGitHub() async {
    try {

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.replaceAll('v', '');

      final response = await http.get(
        Uri.parse(GITHUB_API_URL),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Fihirana-App',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String latestVersion = data['tag_name'].toString().replaceAll('v', '');
        final releaseUrl = data['html_url'];
        final releaseNotes = data['body'] ?? 'No release notes available';
        final apkAsset = data['assets']?.firstWhere(
          (asset) => asset['name'].toString().endsWith('.apk'),
          orElse: () => null,
        );
        final downloadUrl = apkAsset?['browser_download_url'] ?? releaseUrl;

        final bool isNewer = _isNewerVersion(currentVersion, latestVersion);
        if (kDebugMode) {
          print(
            '🔄 Version comparison: $currentVersion -> $latestVersion = ${isNewer ? "update available" : "up to date"}');
        }

        if (isNewer) {
          _cachedDownloadUrl = downloadUrl;
          _cachedVersion = latestVersion;
          _cachedReleaseNotes = releaseNotes;
          await _showUpdateNotification();
        } else {
          stopPeriodicCheck();
        }
      } else {
      }
    } catch (e) {
    }
  }

  static Future<void> _showUpdateNotification() async {
    if (_cachedVersion == null || _cachedDownloadUrl == null) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: UPDATE_NOTIFICATION_ID,
        channelKey: 'basic_channel',
        title: 'Misy rindrambaiko vaovao',
        body:
            'Version $_cachedVersion dia efa azo ampiasaina!\n\nVaovao:\n$_cachedReleaseNotes',
        payload: {'url': _cachedDownloadUrl},
        notificationLayout: NotificationLayout.BigText,
        color: const Color(0xFF9D50DD),
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'UPDATE',
          label: 'Haka',
        ),
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Mbola tsy izao aloha',
          actionType: ActionType.Default,
        ),
      ],
    );
  }

  static void initializeActionListeners() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  static Future<void> _downloadAndInstallUpdate(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
      } else {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: url,
        );
        await intent.launch();
      }
    } catch (e) {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: UPDATE_NOTIFICATION_ID + 1,
          channelKey: 'basic_channel',
          title: 'Tsy afaka nalaina',
          body:
              'Tsy afaka nalaina ny rindrambaiko vaovao. Avereno afaka kelikely azafady.',
          color: const Color(0xFF9D50DD),
        ),
      );
    }
  }

  static bool _isNewerVersion(String currentVersion, String latestVersion) {
    try {
      List<int> current = currentVersion.split('.').map(int.parse).toList();
      List<int> latest = latestVersion.split('.').map(int.parse).toList();

      while (current.length < latest.length) {
        current.add(0);
      }
      while (latest.length < current.length) {
        latest.add(0);
      }

      for (int i = 0; i < current.length; i++) {
        if (latest[i] > current[i]) return true;
        if (latest[i] < current[i]) return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}