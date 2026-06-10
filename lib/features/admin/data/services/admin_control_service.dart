import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin configuration model
class AdminConfig {
  final bool updatesEnabled;
  final bool forceUpdate;
  final String? minSupportedVersion;
  final String? blockedVersion;
  final String? recommendedVersion;
  final String? adminMessage;
  final bool emergencyMode;
  final DateTime? configTimestamp;
  final List<String> allowedVersions;
  final Map<String, dynamic>? featureFlags;

  const AdminConfig({
    this.updatesEnabled = true,
    this.forceUpdate = false,
    this.minSupportedVersion,
    this.blockedVersion,
    this.recommendedVersion,
    this.adminMessage,
    this.emergencyMode = false,
    this.configTimestamp,
    this.allowedVersions = const [],
    this.featureFlags,
  });

  factory AdminConfig.fromMap(Map<String, dynamic> map) {
    return AdminConfig(
      updatesEnabled: map['updatesEnabled'] ?? true,
      forceUpdate: map['forceUpdate'] ?? false,
      minSupportedVersion: map['minSupportedVersion'],
      blockedVersion: map['blockedVersion'],
      recommendedVersion: map['recommendedVersion'],
      adminMessage: map['adminMessage'],
      emergencyMode: map['emergencyMode'] ?? false,
      configTimestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : null,
      allowedVersions: List<String>.from(map['allowedVersions'] ?? []),
      featureFlags: map['featureFlags'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'updatesEnabled': updatesEnabled,
      'forceUpdate': forceUpdate,
      'minSupportedVersion': minSupportedVersion,
      'blockedVersion': blockedVersion,
      'recommendedVersion': recommendedVersion,
      'adminMessage': adminMessage,
      'emergencyMode': emergencyMode,
      'timestamp':
          configTimestamp != null ? Timestamp.fromDate(configTimestamp!) : null,
      'allowedVersions': allowedVersions,
      'featureFlags': featureFlags,
    };
  }

  bool isVersionAllowed(String version) {
    if (allowedVersions.isEmpty) return true;
    return allowedVersions.contains(version);
  }

  bool isVersionBlocked(String version) {
    return blockedVersion == version;
  }

  bool shouldForceUpdate(String currentVersion) {
    if (!forceUpdate) return false;
    if (minSupportedVersion == null) return false;
    return _isNewerVersion(minSupportedVersion!, currentVersion);
  }

  bool _isNewerVersion(String version1, String version2) {
    try {
      final v1Parts =
          version1.split('.').map((s) => int.tryParse(s) ?? 0).toList();
      final v2Parts =
          version2.split('.').map((s) => int.tryParse(s) ?? 0).toList();

      for (int i = 0; i < v1Parts.length && i < v2Parts.length; i++) {
        if (v1Parts[i] > v2Parts[i]) return true;
        if (v1Parts[i] < v2Parts[i]) return false;
      }
      return v1Parts.length > v2Parts.length;
    } catch (e) {
      return false;
    }
  }
}

/// Admin control service for managing app updates remotely
class AdminControlService {
  static const String _configCollection = 'app_config';
  static const String _updateControlDoc = 'update_control';
  static const String _cachedConfigKey = 'cached_admin_config';
  static const Duration _cacheExpiry = Duration(minutes: 30);

  static AdminConfig? _cachedConfig;
  static DateTime? _lastConfigFetch;

  /// Fetch admin configuration from Firestore
  static Future<AdminConfig> fetchAdminConfig() async {
    try {
      // Check cache first
      if (_cachedConfig != null &&
          _lastConfigFetch != null &&
          DateTime.now().difference(_lastConfigFetch!) < _cacheExpiry) {
        if (kDebugMode) {
          print('📋 Using cached admin config');
        }
        return _cachedConfig!;
      }

      final docRef = FirebaseFirestore.instance
          .collection(_configCollection)
          .doc(_updateControlDoc);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final config = AdminConfig.fromMap(docSnapshot.data()!);
        _cachedConfig = config;
        _lastConfigFetch = DateTime.now();

        // Cache locally
        await _cacheConfigLocally(config);

        if (kDebugMode) {
          print('📋 Fetched admin config from Firestore');
          print('   Updates enabled: ${config.updatesEnabled}');
          print('   Force update: ${config.forceUpdate}');
          print('   Blocked version: ${config.blockedVersion}');
          print('   Emergency mode: ${config.emergencyMode}');
        }

        return config;
      } else {
        // Create default config if none exists
        const defaultConfig = AdminConfig();
        await setAdminConfig(defaultConfig);
        return defaultConfig;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to fetch admin config: $e');
      }

      // Fallback to cached config or default
      return await _getCachedConfigOrDefault();
    }
  }

  /// Set admin configuration (admin only)
  static Future<void> setAdminConfig(AdminConfig config) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection(_configCollection)
          .doc(_updateControlDoc);

      final configWithTimestamp = AdminConfig(
        updatesEnabled: config.updatesEnabled,
        forceUpdate: config.forceUpdate,
        minSupportedVersion: config.minSupportedVersion,
        blockedVersion: config.blockedVersion,
        recommendedVersion: config.recommendedVersion,
        adminMessage: config.adminMessage,
        emergencyMode: config.emergencyMode,
        configTimestamp: DateTime.now(),
        allowedVersions: config.allowedVersions,
        featureFlags: config.featureFlags,
      );

      await docRef.set(configWithTimestamp.toMap());

      _cachedConfig = configWithTimestamp;
      _lastConfigFetch = DateTime.now();

      await _cacheConfigLocally(configWithTimestamp);

      if (kDebugMode) {
        print('✅ Admin config updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to set admin config: $e');
      }
      throw Exception('Failed to update admin configuration: $e');
    }
  }

  /// Check if updates are currently allowed
  static Future<bool> areUpdatesAllowed() async {
    final config = await fetchAdminConfig();
    return config.updatesEnabled && !config.emergencyMode;
  }

  /// Check if a specific version is blocked
  static Future<bool> isVersionBlocked(String version) async {
    final config = await fetchAdminConfig();
    return config.isVersionBlocked(version);
  }

  /// Check if update should be forced
  static Future<bool> shouldForceUpdate(String currentVersion) async {
    final config = await fetchAdminConfig();
    return config.shouldForceUpdate(currentVersion);
  }

  /// Get admin message for users
  static Future<String?> getAdminMessage() async {
    final config = await fetchAdminConfig();
    return config.adminMessage;
  }

  /// Get recommended version
  static Future<String?> getRecommendedVersion() async {
    final config = await fetchAdminConfig();
    return config.recommendedVersion;
  }

  /// Emergency stop - disable all updates immediately
  static Future<void> emergencyStop() async {
    await fetchAdminConfig();
    final emergencyConfig = AdminConfig(
      updatesEnabled: false,
      emergencyMode: true,
      adminMessage: 'Updates temporarily disabled by administrator.',
      configTimestamp: DateTime.now(),
    );
    await setAdminConfig(emergencyConfig);
  }

  /// Clear emergency mode and restore normal operation
  static Future<void> clearEmergencyMode() async {
    await fetchAdminConfig();
    final normalConfig = AdminConfig(
      updatesEnabled: true,
      emergencyMode: false,
      adminMessage: null,
      configTimestamp: DateTime.now(),
    );
    await setAdminConfig(normalConfig);
  }

  /// Cache configuration locally for offline scenarios
  static Future<void> _cacheConfigLocally(AdminConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedConfigKey, jsonEncode(config.toMap()));
      await prefs.setString(
          'config_cache_time', DateTime.now().toIso8601String());
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to cache config locally: $e');
      }
    }
  }

  /// Get cached configuration or default
  static Future<AdminConfig> _getCachedConfigOrDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedConfigJson = prefs.getString(_cachedConfigKey);

      if (cachedConfigJson != null) {
        final configMap = jsonDecode(cachedConfigJson) as Map<String, dynamic>;
        return AdminConfig.fromMap(configMap);
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to get cached config: $e');
      }
    }

    // Return default configuration
    return const AdminConfig();
  }

  /// Clear local cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedConfigKey);
      await prefs.remove('config_cache_time');
      _cachedConfig = null;
      _lastConfigFetch = null;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to clear cache: $e');
      }
    }
  }

  /// Get feature flag value
  static Future<bool> getFeatureFlag(String flagName, bool defaultValue) async {
    final config = await fetchAdminConfig();
    return config.featureFlags?[flagName] ?? defaultValue;
  }

  /// Check if app is in maintenance mode
  static Future<bool> isMaintenanceMode() async {
    final config = await fetchAdminConfig();
    return config.emergencyMode;
  }
}
