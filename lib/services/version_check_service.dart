import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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

    // Request notification permission
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // Initialize action listeners
    initializeActionListeners();

    // Start periodic check
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
      print('🔍 Starting version check...');

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version.replaceAll('v', '');
      print('📱 Current app version: $currentVersion');

      print('🌐 Fetching latest release from GitHub...');
      // Get latest release from GitHub
      final response = await http.get(
        Uri.parse(GITHUB_API_URL),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Fihirana-App',
        },
      );

      print('🌐 GitHub API response status: ${response.statusCode}');

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

        print('📦 Latest version on GitHub: $latestVersion');
        print('🔗 Release URL: $releaseUrl');
        print('📝 Release notes: $releaseNotes');
        print('📥 Download URL: $downloadUrl');

        // Compare versions
        final bool isNewer = _isNewerVersion(currentVersion, latestVersion);
        print(
            '🔄 Version comparison: $currentVersion -> $latestVersion = ${isNewer ? "update available" : "up to date"}');

        if (isNewer) {
          print('✨ Showing update notification');
          _cachedDownloadUrl = downloadUrl;
          _cachedVersion = latestVersion;
          _cachedReleaseNotes = releaseNotes;
          await _showUpdateNotification();
        } else {
          print('✅ App is up to date');
          stopPeriodicCheck();
        }
      } else {
        print('❌ Failed to check for updates: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ Error checking for updates: $e');
      print('Stack trace: $stackTrace');
    }
  }

  static Future<void> _showUpdateNotification() async {
    if (_cachedVersion == null || _cachedDownloadUrl == null) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: UPDATE_NOTIFICATION_ID,
        channelKey: 'basic_channel',
        title: 'Misy rindrambaiko vaovao',
        body: 'Version $_cachedVersion dia efa azo ampiasaina!\n\nVaovao:\n$_cachedReleaseNotes',
        payload: {'url': _cachedDownloadUrl},
        notificationLayout: NotificationLayout.BigText,
        color: const Color(0xFF9D50DD),
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'UPDATE',
          label: 'Alaina',
        ),
        NotificationActionButton(
          key: 'DISMISS',
          label: 'Amin\'ny manaraka',
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

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyPressed == 'UPDATE') {
      final url = receivedAction.payload?['url'];
      if (url != null) {
        await _downloadAndInstallUpdate(url);
        stopPeriodicCheck();
      }
    } else if (receivedAction.buttonKeyPressed == 'DISMISS') {
      stopPeriodicCheck();
    }
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
        print('Could not launch $url');
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: url,
        );
        await intent.launch();
      }
    } catch (e) {
      print('Error launching URL: $e');
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: UPDATE_NOTIFICATION_ID + 1,
          channelKey: 'basic_channel',
          title: 'Tsy afaka nalaina',
          body: 'Tsy afaka nalaina ny rindrambaiko vaovao. Avereno afaka kelikely azafady.',
          color: const Color(0xFF9D50DD),
        ),
      );
    }
  }

  static bool _isNewerVersion(String currentVersion, String latestVersion) {
    try {
      List<int> current = currentVersion.split('.').map(int.parse).toList();
      List<int> latest = latestVersion.split('.').map(int.parse).toList();

      // Pad versions to same length if necessary
      while (current.length < latest.length) current.add(0);
      while (latest.length < current.length) latest.add(0);

      // Compare version numbers
      for (int i = 0; i < current.length; i++) {
        if (latest[i] > current[i]) return true;
        if (latest[i] < current[i]) return false;
      }
      return false; // Versions are equal
    } catch (e) {
      print('Error comparing versions: $e');
      return false;
    }
  }
}
