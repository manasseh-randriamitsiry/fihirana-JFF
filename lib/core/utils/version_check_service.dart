import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/core/utils/apk_download_service.dart';
import 'pubspec_service.dart';
import 'package:fihirana/features/admin/data/services/admin_control_service.dart';
import 'package:fihirana/shared/widgets/common/update_notification.dart';
import 'package:fihirana/shared/widgets/common/notification_channels.dart';

class VersionCheckService {
  static const String githubApiUrl =
      'https://api.github.com/repos/manasseh-randriamitsiry/fihirana-JFF/releases/latest';

  static const String lastCheckKey = 'last_version_check';
  static const String dismissedVersionKey = 'dismissed_update_version';
  static const String installedVersionKey = 'installed_update_version';
  static const String githubTokenKey = 'github_token';
  static const Duration checkInterval = Duration(hours: 1);
  static const int updateNotificationId = 1;

  static Timer? _notificationTimer;
  static String? _cachedDownloadUrl;
  static String? _cachedVersion;
  static String? _cachedReleaseNotes;

  static AppUpdateInfo? _updateInfo;
  static bool _flexibleUpdateAvailable = false;
  static VoidCallback? _onUpdateAvailable;
  static VoidCallback? _onFlexibleUpdateDownloaded;
  static bool _isUpToDate = false;
  static bool _hasCheckedOnStartup = false;

  // Get GitHub token from SharedPreferences for API authentication
  static Future<String> getGithubToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(githubTokenKey) ?? '';
    } catch (e) {
      return '';
    }
  }

  // Set GitHub token for API authentication
  static Future<void> setGithubToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(githubTokenKey, token);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save GitHub token: $e');
      }
    }
  }

  static void setOnUpdateAvailableCallback(VoidCallback callback) {
    _onUpdateAvailable = callback;
  }

  static void setOnFlexibleUpdateDownloadedCallback(VoidCallback callback) {
    _onFlexibleUpdateDownloaded = callback;
  }

  static Future<void> initializeNotifications() async {
    await NotificationChannelBuilder.initializeAllChannels();
  }

  static void startPeriodicCheck() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(checkInterval, (timer) {
      checkForUpdate();
    });
  }

  static void stopPeriodicCheck() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  static Future<void> checkForUpdate() async {
    try {
      // Check admin control first
      final adminConfig = await AdminControlService.fetchAdminConfig();
      final currentVersion = await PubspecService.getAppVersion();

      // Check if updates are disabled
      if (!adminConfig.updatesEnabled) {
        if (kDebugMode) {
          print('🚫 Updates disabled by administrator');
        }
        stopPeriodicCheck();
        return;
      }

      // Check if current version is blocked
      if (adminConfig.isVersionBlocked(currentVersion)) {
        if (kDebugMode) {
          print('🚫 Current version is blocked by administrator');
        }
        // Force update for blocked versions
        await _checkForUpdateFromGitHub();
        return;
      }

      // Check emergency mode
      if (adminConfig.emergencyMode) {
        if (kDebugMode) {
          print('🚨 Emergency mode active - updates disabled');
        }
        stopPeriodicCheck();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final dismissedVersion = prefs.getString(dismissedVersionKey);

      // First check GitHub for the latest version
      final githubHasUpdate = await _checkGitHubVersionOnly();

      if (kDebugMode) {
        print('🔍 GitHub check result: $githubHasUpdate');
      }

      // Only proceed with InAppUpdate if GitHub shows there's an update
      if (!githubHasUpdate) {
        if (kDebugMode) {
          print('✅ Up to date, stopping periodic check');
        }
        stopPeriodicCheck();
        return;
      }

       // Check InAppUpdate as fallback
       try {
         final updateInfo = await InAppUpdate.checkForUpdate();
         _updateInfo = updateInfo;

         if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
           // Don't show notification if user already dismissed this version
           if (dismissedVersion == currentVersion) {
             stopPeriodicCheck();
             return;
           }

           _onUpdateAvailable?.call();

           // Check if admin wants to force update
           if (adminConfig.forceUpdate || updateInfo.updatePriority >= 4) {
             await _performImmediateUpdate();
           } else {
             // Start flexible update for non-critical updates
             await startFlexibleUpdate();
           }
         } else {
           // InAppUpdate says no update, but GitHub said yes.
           // This means the Play Store is behind or app is not from Play Store. Fallback to GitHub update.
           if (githubHasUpdate) {
             if (kDebugMode) {
               print(
                   '⚠️ InAppUpdate found nothing, but GitHub has update. Falling back to GitHub.');
             }
             await _checkForUpdateFromGitHub();
           } else {
             stopPeriodicCheck();
           }
         }
       } catch (playStoreError) {
         // InAppUpdate failed, likely because app is not from Play Store
         if (kDebugMode) {
           print('❌ InAppUpdate failed: $playStoreError');
           print('📱 App likely not installed from Play Store, falling back to GitHub update');
         }

         // Fallback to GitHub update
         if (githubHasUpdate) {
           await _checkForUpdateFromGitHub();
         } else {
           stopPeriodicCheck();
         }
       }
    } catch (e) {
      await _checkForUpdateFromGitHub();
    }
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
          // Try flexible update first, fallback to immediate
          try {
            await startFlexibleUpdate();
          } catch (e) {
            if (kDebugMode) {
              print('❌ Flexible update failed, trying immediate update: $e');
            }
            await _performImmediateUpdate();
          }
        }
        stopPeriodicCheck();
      } else if (_cachedDownloadUrl != null) {
        await _downloadAndInstallUpdate(_cachedDownloadUrl!);
        stopPeriodicCheck();
      }
    } else if (receivedAction.buttonKeyPressed == 'DISMISS') {
      // Save the current version as dismissed to prevent future notifications
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = await PubspecService.getAppVersion();
      await prefs.setString(dismissedVersionKey, currentVersion);

      stopPeriodicCheck();
    } else if (receivedAction.buttonKeyPressed == 'CANCEL_DOWNLOAD') {
      await ApkDownloadService.handleDownloadAction('CANCEL_DOWNLOAD');
    }
  }

  static Future<void> _performImmediateUpdate() async {
    try {
      if (_updateInfo?.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        final result = await InAppUpdate.performImmediateUpdate();

        if (result == AppUpdateResult.userDeniedUpdate) {
        } else if (result == AppUpdateResult.inAppUpdateFailed) {
          if (_cachedDownloadUrl != null) {
            await _downloadAndInstallUpdate(_cachedDownloadUrl!);
          }
        } else if (result == AppUpdateResult.success) {}
      }
} catch (e) {
      final isNotificationAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (isNotificationAllowed) {
        await UpdateNotificationBuilder.showDownloadError(error: e.toString());
      }
    }
  }

  static Future<void> startFlexibleUpdate() async {
    try {
      if (_updateInfo?.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        _flexibleUpdateAvailable = true;

        final isNotificationAllowed = await AwesomeNotifications().isNotificationAllowed();
        if (isNotificationAllowed) {
          await UpdateNotificationBuilder.showFlexibleUpdateDownloading();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Flexible update failed: $e');
      }
      rethrow;
    }
  }

  static Future<void> _completeFlexibleUpdate() async {
    try {
      if (_flexibleUpdateAvailable) {
        await InAppUpdate.completeFlexibleUpdate();
        _flexibleUpdateAvailable = false;
        if (kDebugMode) {
          print('✅ Flexible update completed successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Flexible update completion failed: $e');
      }
      rethrow;
    }
  }

  static Future<bool> _isInstalledFromPlayStore() async {
    try {
      // For in-app updates to work, the app must be installed from Google Play Store
      // We can check this by trying to use InAppUpdate.checkForUpdate()
      // If it succeeds without errors, the app is likely from Play Store
      final updateInfo = await InAppUpdate.checkForUpdate();
      return updateInfo.updateAvailability != UpdateAvailability.unknown;
    } catch (e) {
      // If InAppUpdate fails, the app is likely not from Play Store
      if (kDebugMode) {
        print('❌ InAppUpdate check failed, assuming not from Play Store: $e');
      }
      return false;
    }
  }

  static Future<bool> checkForUpdateManually() async {
    try {
      // Check admin control first
      final adminConfig = await AdminControlService.fetchAdminConfig();
      final currentVersion = await PubspecService.getAppVersion();

      // Check if updates are disabled
      if (!adminConfig.updatesEnabled) {
        if (kDebugMode) {
          print('🚫 Updates disabled by administrator');
        }
        return false;
      }

      // Check if current version is blocked
      if (adminConfig.isVersionBlocked(currentVersion)) {
        if (kDebugMode) {
          print('🚫 Current version is blocked - forcing update');
        }
        // Continue with update check for blocked versions
      }

      // Check emergency mode
      if (adminConfig.emergencyMode) {
        if (kDebugMode) {
          print('🚨 Emergency mode active - updates disabled');
        }
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final dismissedVersion = prefs.getString(dismissedVersionKey);

      final headers = {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'Fihirana-JFF-App/1.0',
      };

      // Add GitHub token if available (for higher rate limit)
      final githubToken = await getGithubToken();
      if (githubToken.isNotEmpty) {
        headers['Authorization'] = 'token $githubToken';
        if (kDebugMode) {
          print('🔑 Using authenticated GitHub API request');
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Using unauthenticated GitHub API request (rate limited)');
        }
      }

      final response = await http
          .get(
            Uri.parse(githubApiUrl),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      if (kDebugMode) {
        print('🌐 GitHub API response status: ${response.statusCode}');
        if (response.statusCode != 200) {
          print('❌ GitHub API response body: ${response.body}');
        }
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String latestVersion = data['tag_name'].toString().replaceAll('v', '');
        final releaseNotes = data['body'] ?? 'No release notes available';

        if (kDebugMode) {
          print('✅ GitHub API Success - Latest Version: $latestVersion');
        }

        // Get device architecture
        String deviceArch = _getDeviceArchitecture();

        if (kDebugMode) {
          print('🔍 Device Arch: $deviceArch');
          if (data['assets'] != null) {
            final assetsList = data['assets'] as List;
            print('📦 Total Assets: ${assetsList.length}');
            for (var asset in assetsList) {
              print(
                  '   - ${asset['name']} (digest: ${asset['digest'] != null ? "YES" : "NO"})');
            }
          } else {
            print('❌ No assets found in release data');
          }
        }

        // Try to find architecture-specific APK first, then fallback to universal
        final apkAsset = data['assets']?.firstWhere(
          (asset) {
            final name = asset['name'].toString().toLowerCase();
            return name.contains(deviceArch) && name.endsWith('.apk');
          },
          orElse: () => data['assets']?.firstWhere(
            (asset) {
              final name = asset['name'].toString().toLowerCase();
              return name.contains('universal') && name.endsWith('.apk');
            },
            orElse: () => data['assets']?.firstWhere(
              (asset) => asset['name'].toString().endsWith('.apk'),
              orElse: () => null,
            ),
          ),
        );

        if (kDebugMode) {
          print('🎯 Selected Asset: ${apkAsset?['name']}');
          if (apkAsset != null) {
            print(
                '📄 Asset has digest field: ${apkAsset.containsKey('digest')}');
            print('📄 Asset digest value: ${apkAsset['digest']}');
            debugPrint('📄 All asset keys: ${apkAsset.keys.toList()}');
            // Log all asset values for debugging
            debugPrint('📄 Full asset data:');
            apkAsset.forEach((key, value) {
              debugPrint('   $key: $value');
            });
          }
        }

        final downloadUrl =
            apkAsset?['browser_download_url'] ?? data['html_url'];

        final bool isNewer = _isNewerVersion(currentVersion, latestVersion);
        final bool isSameVersion = currentVersion == latestVersion;

        if (kDebugMode) {
          print(
              '🔄 Manual check: current=$currentVersion, latest=$latestVersion, newer=$isNewer, same=$isSameVersion');
        }

        // Update the up-to-date flag
        _isUpToDate = !isNewer;
        _hasCheckedOnStartup = true;

// Cache version info for download
        if (isNewer) {
          _cachedVersion = latestVersion;
          _cachedDownloadUrl = downloadUrl;
          _cachedReleaseNotes = releaseNotes;
          if (kDebugMode) {
            print('💾 Caching update info:');
            print('   Version: $_cachedVersion');
            print('   URL: $_cachedDownloadUrl');
          }
        } else {
          // Clear cached info if up to date
          _cachedVersion = null;
          _cachedDownloadUrl = null;
          _cachedReleaseNotes = null;
        }

        // Only return true if there's actually a newer version and not dismissed
        if (isNewer && dismissedVersion != currentVersion) {
          _onUpdateAvailable?.call();
          return true;
        }

        // If we're up to date, clear any dismissed version
        if (!isNewer && dismissedVersion != null) {
          await clearDismissedVersion();
        }

        return false;
      }

      if (kDebugMode) {
        print('❌ GitHub API failed with status: ${response.statusCode}');
      }

      // Try InAppUpdate only if installed from Play Store
      final isFromPlayStore = await _isInstalledFromPlayStore();
      if (isFromPlayStore) {
        try {
          final updateInfo = await InAppUpdate.checkForUpdate();
          _updateInfo = updateInfo;

          if (updateInfo.updateAvailability ==
              UpdateAvailability.updateAvailable) {
            // Don't show update if user already dismissed this version
            if (dismissedVersion == currentVersion) {
              return false;
            }

            _onUpdateAvailable?.call();
            return true;
          } else {
            // Update the up-to-date flag for InAppUpdate result
            _isUpToDate = true;
            _hasCheckedOnStartup = true;
            return false;
          }
        } catch (playStoreError) {
          if (kDebugMode) {
            print('❌ InAppUpdate failed: $playStoreError');
          }
          // If Play Store check fails, assume up-to-date to avoid errors
          _isUpToDate = true;
          _hasCheckedOnStartup = true;
          return false;
        }
      } else {
        if (kDebugMode) {
          print('📱 Not installed from Play Store, skipping InAppUpdate check');
        }
        // If not from Play Store and GitHub failed, assume up-to-date
        _isUpToDate = true;
        _hasCheckedOnStartup = true;
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Manual check failed: $e');
      }
      // On error, assume up-to-date to avoid constant error states
      _isUpToDate = true;
      _hasCheckedOnStartup = true;
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

  static Future<bool> _checkGitHubVersionOnly() async {
    try {
      final currentVersion = await PubspecService.getAppVersion();

      final response = await http.get(
        Uri.parse(githubApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Fihirana-App',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String latestVersion = data['tag_name'].toString().replaceAll('v', '');

        final bool isNewer = _isNewerVersion(currentVersion, latestVersion);
        final bool isSameVersion = currentVersion == latestVersion ||
            currentVersion == latestVersion.replaceAll('v', '');

        if (kDebugMode) {
          print(
              '🔍 GitHub version check: current="$currentVersion", latest="$latestVersion", newer=$isNewer, same=$isSameVersion');
        }

        // If versions are the same, clear any dismissed version and stop checking
        if (isSameVersion) {
          await clearUpdateState();
          return false;
        }

        return isNewer;
      } else {
        if (kDebugMode) {
          print('❌ Failed to fetch release info: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking GitHub for updates: $e');
      }
      return false;
    }
  }

  static Future<void> _checkForUpdateFromGitHub() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissedVersion = prefs.getString(dismissedVersionKey);
      final currentVersion = await PubspecService.getAppVersion();

      final response = await http.get(
        Uri.parse(githubApiUrl),
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

        // Get device architecture
        String deviceArch = _getDeviceArchitecture();

        // Try to find architecture-specific APK first, then fallback to universal
        final apkAsset = data['assets']?.firstWhere(
          (asset) {
            final name = asset['name'].toString().toLowerCase();
            return name.contains(deviceArch) && name.endsWith('.apk');
          },
          orElse: () => data['assets']?.firstWhere(
            (asset) {
              final name = asset['name'].toString().toLowerCase();
              return name.contains('universal') && name.endsWith('.apk');
            },
            orElse: () => data['assets']?.firstWhere(
              (asset) => asset['name'].toString().endsWith('.apk'),
              orElse: () => null,
            ),
          ),
        );

        final downloadUrl = apkAsset?['browser_download_url'] ?? releaseUrl;

        final bool isNewer = _isNewerVersion(currentVersion, latestVersion);
        final bool isSameVersion = currentVersion == latestVersion;

        if (kDebugMode) {
          print(
              '🔄 Version comparison: $currentVersion -> $latestVersion = ${isNewer ? "update available" : isSameVersion ? "up to date" : "up to date"}');
        }

        // Clear dismissed version if we're up to date
        if (!isNewer && dismissedVersion != null) {
          await clearDismissedVersion();
        }

        // Only show notification if there's actually a newer version
        if (isNewer && dismissedVersion != currentVersion) {
          // Clear dismissed version if this is a newer version than what was dismissed
          if (dismissedVersion != null &&
              _isNewerVersion(dismissedVersion, latestVersion)) {
            await clearDismissedVersion();
          }

          _cachedDownloadUrl = downloadUrl;
          _cachedVersion = latestVersion;
          _cachedReleaseNotes = releaseNotes;
          _onUpdateAvailable?.call();
          await _showUpdateNotification();
        } else {
          // We're up to date, so don't show update notification
          await clearUpdateState();
        }
      } else {
        if (kDebugMode) {
          print('❌ Failed to fetch release info: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking GitHub for updates: $e');
      }
    }
  }

static Future<void> _showUpdateNotification() async {
    if (_cachedVersion == null || _cachedDownloadUrl == null) return;

    // Check if notifications are allowed
    final isNotificationAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (isNotificationAllowed) {
      await UpdateNotificationBuilder.showUpdateAvailable(
        version: _cachedVersion!,
        releaseNotes: _cachedReleaseNotes,
        downloadUrl: _cachedDownloadUrl,
      );
    } else {
      // Show dialog asking user to enable notifications
      await _showEnableNotificationDialog();
    }
  }

  static Future<void> _showEnableNotificationDialog() async {
    final context = Get.context;
    if (context == null) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nouvelle mise à jour disponible'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('La version ${_cachedVersion ?? ""} est maintenant disponible !'),
              const SizedBox(height: 8),
              if (_cachedReleaseNotes != null && _cachedReleaseNotes!.isNotEmpty) ...[
                const Text('Nouvelles :'),
                const SizedBox(height: 4),
                Text(_cachedReleaseNotes!),
                const SizedBox(height: 8),
              ],
              const Text('Impossible d\'afficher la notification car la permission n\'est pas accordée. Accordez la permission de notification pour installer la mise à jour.'),
            ],
          ),
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
                final granted = await AwesomeNotifications().requestPermissionToSendNotifications();
                if (granted) {
                  // Show the update notification after permission is granted
                  await _showUpdateNotification();
                }
              },
              child: const Text('Accorder la permission'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Directly download and install without notification
                _downloadAndInstallUpdate(_cachedDownloadUrl!);
              },
              child: const Text('Continuer quand même'),
            ),
          ],
        );
      },
    );
  }

  static void initializeActionListeners() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  static Future<void> _downloadAndInstallUpdate(String url) async {
    try {
      if (_cachedVersion != null) {
// Use the new APK download service
        await ApkDownloadService.downloadAndInstallApk(
          url,
          _cachedVersion!,
        );
      } else {
        // Fallback to external browser
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
      }
    } catch (e) {
      final isNotificationAllowed = await AwesomeNotifications().isNotificationAllowed();
      if (isNotificationAllowed) {
        await UpdateNotificationBuilder.showInstallError(error: e.toString());
      }
    }
  }

  static bool _isNewerVersion(String currentVersion, String latestVersion) {
    try {
      // Clean version strings (remove 'v' prefix and any other non-numeric characters except dots)
      String cleanCurrent = currentVersion.replaceAll(RegExp(r'[^0-9.]'), '');
      String cleanLatest = latestVersion.replaceAll(RegExp(r'[^0-9.]'), '');

      if (kDebugMode) {
        print(
            '🔍 Version cleaning: "$currentVersion" -> "$cleanCurrent", "$latestVersion" -> "$cleanLatest"');
      }

      List<int> current =
          cleanCurrent.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      List<int> latest =
          cleanLatest.split('.').map((s) => int.tryParse(s) ?? 0).toList();

      // Pad shorter version with zeros
      while (current.length < latest.length) {
        current.add(0);
      }
      while (latest.length < current.length) {
        latest.add(0);
      }

      // Compare version numbers
      for (int i = 0; i < current.length; i++) {
        if (latest[i] > current[i]) return true;
        if (latest[i] < current[i]) return false;
      }
      return false; // Versions are equal
    } catch (e) {
      if (kDebugMode) {
        print('❌ Version comparison error: $e');
      }
      return false;
    }
  }

  static Future<void> clearDismissedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(dismissedVersionKey);
  }

  static Future<void> clearUpdateState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(dismissedVersionKey);
    await prefs.remove(installedVersionKey);
    _updateInfo = null;
    _cachedDownloadUrl = null;
    _cachedVersion = null;
    _cachedReleaseNotes = null;
    _flexibleUpdateAvailable = false;
    stopPeriodicCheck();
  }

  static Future<void> downloadAndInstallLatestVersion() async {
    if (_cachedDownloadUrl != null && _cachedVersion != null) {
      await ApkDownloadService.downloadAndInstallApk(
        _cachedDownloadUrl!,
        _cachedVersion!,
      );
    } else {
      throw Exception(
          'No update information available. Please check for updates first.');
    }
  }

  static String? getCachedVersion() {
    return _cachedVersion;
  }

  static String? getCachedReleaseNotes() {
    return _cachedReleaseNotes;
  }

  static bool hasUpdateCached() {
    return _cachedVersion != null && _cachedDownloadUrl != null;
  }

  /// Detects the device's CPU architecture for APK selection
  /// Returns architecture string that matches GitHub release APK naming
  static String _getDeviceArchitecture() {
    try {
      // Get the ABI list from Platform
      final abis = Platform.version.contains('arm64') ||
              Platform.version.contains('aarch64')
          ? 'arm64-v8a'
          : Platform.version.contains('arm') ||
                  Platform.version.contains('armeabi')
              ? 'armeabi-v7a'
              : Platform.version.contains('x86_64')
                  ? 'x86_64'
                  : 'x86';

      if (kDebugMode) {
        print('🔍 Detected device architecture: $abis');
      }

      return abis;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error detecting architecture: $e, defaulting to arm64-v8a');
      }
      // Default to most common architecture
      return 'arm64-v8a';
    }
  }

  /// Check for updates on app startup without showing notifications
  static Future<void> checkForUpdateOnStartup() async {
    if (_hasCheckedOnStartup) return;
    _hasCheckedOnStartup = true;

    try {
      final currentVersion = await PubspecService.getAppVersion();
      final response = await http.get(
        Uri.parse(githubApiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Fihirana-App',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String latestVersion = data['tag_name'].toString().replaceAll('v', '');
        final releaseNotes = data['body'] ?? 'No release notes available';

        // Get device architecture
        String deviceArch = _getDeviceArchitecture();

        // Try to find architecture-specific APK first, then fallback to universal
        final apkAsset = data['assets']?.firstWhere(
          (asset) {
            final name = asset['name'].toString().toLowerCase();
            return name.contains(deviceArch) && name.endsWith('.apk');
          },
          orElse: () => data['assets']?.firstWhere(
            (asset) {
              final name = asset['name'].toString().toLowerCase();
              return name.contains('universal') && name.endsWith('.apk');
            },
            orElse: () => data['assets']?.firstWhere(
              (asset) => asset['name'].toString().endsWith('.apk'),
              orElse: () => null,
            ),
          ),
        );

        final downloadUrl =
            apkAsset?['browser_download_url'] ?? data['html_url'];

        final bool isNewer = _isNewerVersion(currentVersion, latestVersion);

        if (isNewer) {
          _isUpToDate = false;
          _cachedVersion = latestVersion;
          _cachedDownloadUrl = downloadUrl;
          _cachedReleaseNotes = releaseNotes;
          _onUpdateAvailable?.call();
        } else {
          _isUpToDate = true;
          _cachedVersion = null;
          _cachedDownloadUrl = null;
          _cachedReleaseNotes = null;
        }

        if (kDebugMode) {
          print(
              '🔍 Startup update check: current=$currentVersion, latest=$latestVersion, isUpToDate=$_isUpToDate');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Startup update check failed: $e');
      }
      // On error, assume we're up to date to avoid false negatives
      _isUpToDate = true;
    }
  }

  /// Returns true if the app is on the latest version
  static bool isUpToDate() {
    return _isUpToDate;
  }

  /// Returns a description of the update status
  static String getUpdateStatus() {
    if (!_hasCheckedOnStartup) {
      return 'Checking...';
    }
    return _isUpToDate ? 'Up to date' : 'Update available';
  }

  /// Returns true if a manual check has been performed
  static bool hasCheckedManually() {
    return _hasCheckedOnStartup;
  }
}
