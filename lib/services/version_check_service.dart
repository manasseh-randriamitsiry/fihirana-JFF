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
import 'package:in_app_update/in_app_update.dart'; // Added import for in_app_update
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
  static AppUpdateInfo? _updateInfo; // Added to store update info
  static bool _flexibleUpdateAvailable = false; // Track flexible update state
  static VoidCallback? _onUpdateAvailable; // Callback for UI updates
  static VoidCallback? _onFlexibleUpdateDownloaded; // Callback for flexible update completion

  // Method to set update available callback
  static void setOnUpdateAvailableCallback(VoidCallback callback) {
    _onUpdateAvailable = callback;
  }

  // Method to set flexible update downloaded callback
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
      checkForUpdate(); // This will now use in_app_update
    });
  }

  static void stopPeriodicCheck() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  // Modified to use in_app_update package
  static Future<void> checkForUpdate() async {
    try {
      print('🔍 Starting in-app update check...');
      
      // Check for update using in_app_update package
      final updateInfo = await InAppUpdate.checkForUpdate();
      _updateInfo = updateInfo;
      
      print('📱 Update availability: ${updateInfo.updateAvailability}');
      print('📦 Available version code: ${updateInfo.availableVersionCode}');
      print('🔄 Update priority: ${updateInfo.updatePriority}');
      // Removed incorrect property access
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        print('✨ Update available!');
        
        // Get current app version for logging
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;
        print('📱 Current version: $currentVersion');
        print('🔢 Current version code: ${packageInfo.buildNumber}');
        print('🔢 Available version code: ${updateInfo.availableVersionCode}');
        
        // Notify UI if callback is set
        _onUpdateAvailable?.call();
        
        // Decide update type based on priority
        if (updateInfo.updatePriority >= 4) {
          // High priority update - immediate update
          print('🚨 High priority update - performing immediate update');
          await _performImmediateUpdate();
        } else {
          // Regular update - show notification
          print('🔔 Regular update - showing notification');
          await _showInAppUpdateNotification();
        }
      } else {
        print('✅ App is up to date');
        stopPeriodicCheck();
      }
    } catch (e, stackTrace) {
      print('❌ Error checking for in-app updates: $e');
      print('Stack trace: $stackTrace');
      
      // Fallback to GitHub-based check for development/testing
      await _checkForUpdateFromGitHub();
    }
  }

  // New method to show in-app update notification
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

  // Modified action handler to use in_app_update
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyPressed == 'UPDATE') {
      final type = receivedAction.payload?['type'];
      if (type == 'in_app_update' && _updateInfo != null) {
        // Check if it's a flexible update or immediate update
        if (_flexibleUpdateAvailable) {
          // Complete flexible update
          await _completeFlexibleUpdate();
        } else {
          // Perform immediate update
          await _performImmediateUpdate();
        }
        stopPeriodicCheck();
      } else if (_cachedDownloadUrl != null) {
        // Fallback to GitHub-based update
        await _downloadAndInstallUpdate(_cachedDownloadUrl!);
        stopPeriodicCheck();
      }
    } else if (receivedAction.buttonKeyPressed == 'DISMISS') {
      stopPeriodicCheck();
    }
  }

  // New method to perform immediate update
  static Future<void> _performImmediateUpdate() async {
    try {
      if (_updateInfo?.updateAvailability == UpdateAvailability.updateAvailable) {
        print('🚀 Performing immediate update...');
        final result = await InAppUpdate.performImmediateUpdate();
        print('📊 Update result: $result');
        
        // Handle different results with correct enum values
        if (result == AppUpdateResult.userDeniedUpdate) {
          print('❌ User denied the update');
        } else if (result == AppUpdateResult.inAppUpdateFailed) {
          print('❌ In-app update failed');
          // Fallback to GitHub-based update
          if (_cachedDownloadUrl != null) {
            await _downloadAndInstallUpdate(_cachedDownloadUrl!);
          }
        } else if (result == AppUpdateResult.success) {
          print('✅ Update successful');
        }
      }
    } catch (e) {
      print('❌ Error performing in-app update: $e');
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

  // New method to start flexible update
  static Future<void> startFlexibleUpdate() async {
    try {
      if (_updateInfo?.updateAvailability == UpdateAvailability.updateAvailable) {
        print('📥 Starting flexible update...');
        await InAppUpdate.startFlexibleUpdate();
        _flexibleUpdateAvailable = true;
        print('✅ Flexible update started');
        
        // Show notification that download is in progress
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
      print('❌ Error starting flexible update: $e');
    }
  }

  // New method to complete flexible update
  static Future<void> _completeFlexibleUpdate() async {
    try {
      if (_flexibleUpdateAvailable) {
        print('✅ Completing flexible update...');
        await InAppUpdate.completeFlexibleUpdate();
        _flexibleUpdateAvailable = false;
        print('✅ Flexible update completed');
      }
    } catch (e) {
      print('❌ Error completing flexible update: $e');
    }
  }

  // Method to manually trigger update check from UI
  static Future<bool> checkForUpdateManually() async {
    try {
      print('🔍 Manually checking for updates...');
      final updateInfo = await InAppUpdate.checkForUpdate();
      _updateInfo = updateInfo;
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        print('✨ Update available!');
        // Notify UI if callback is set
        _onUpdateAvailable?.call();
        return true;
      } else {
        print('✅ App is up to date');
        return false;
      }
    } catch (e) {
      print('❌ Error manually checking for updates: $e');
      return false;
    }
  }

  // Method to trigger immediate update from UI
  static Future<void> triggerImmediateUpdate() async {
    if (_updateInfo?.updateAvailability == UpdateAvailability.updateAvailable) {
      await _performImmediateUpdate();
    }
  }

  // Method to trigger flexible update from UI
  static Future<void> triggerFlexibleUpdate() async {
    if (_updateInfo?.updateAvailability == UpdateAvailability.updateAvailable) {
      await startFlexibleUpdate();
    }
  }

  // Method to complete flexible update from UI
  static Future<void> completeFlexibleUpdate() async {
    if (_flexibleUpdateAvailable) {
      await _completeFlexibleUpdate();
      // Notify UI that flexible update is completed
      _onFlexibleUpdateDownloaded?.call();
    }
  }

  // Method to check if flexible update is available
  static bool isFlexibleUpdateAvailable() {
    return _flexibleUpdateAvailable;
  }

  // Original GitHub-based check as fallback
  static Future<void> _checkForUpdateFromGitHub() async {
    try {
      print('🔍 Starting GitHub version check (fallback)...');

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