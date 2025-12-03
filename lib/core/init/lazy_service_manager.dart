import 'package:get/get.dart';
import 'package:fihirana/features/bible/data/services/bible_service.dart';
import 'package:fihirana/features/audio/data/services/audio_file_mapping.dart';
import 'package:fihirana/core/utils/version_check_service.dart';
import 'package:fihirana/core/utils/firebase_sync_service.dart';
import 'package:fihirana/features/daily_verse/presentation/controllers/daily_verse_controller.dart';
import 'package:fihirana/features/history/presentation/controllers/history_controller.dart';
import 'package:fihirana/features/playlist/presentation/controllers/playlist_controller.dart';
import 'package:flutter/foundation.dart';

/// Lazy loading manager for non-critical services
/// This ensures that heavy services are only loaded when needed
class LazyServiceManager {
  static final LazyServiceManager _instance = LazyServiceManager._internal();
  factory LazyServiceManager() => _instance;
  LazyServiceManager._internal();

  final Map<String, bool> _loadedServices = {};
  final Map<String, Future<void> Function()> _serviceLoaders = {};

  /// Initialize lazy service loaders
  void initialize() {
    _serviceLoaders.addAll({
      'bible_data': _loadBibleData,
      'daily_verse': _loadDailyVerseController,
      'history': _loadHistoryController,
      'playlist': _loadPlaylistController,
      'version_check': _loadVersionCheck,
      'audio_mapping': _loadAudioMapping,
      'firebase_sync': _loadFirebaseSync,
    });
  }

  /// Load a specific service on demand
  Future<T> loadService<T>(String serviceName) async {
    if (_loadedServices[serviceName] == true) {
      return Get.find<T>();
    }

    final loader = _serviceLoaders[serviceName];
    if (loader == null) {
      throw Exception('Service $serviceName not registered for lazy loading');
    }

    await loader();
    _loadedServices[serviceName] = true;
    
    return Get.find<T>();
  }

  /// Check if service is already loaded
  bool isServiceLoaded(String serviceName) {
    return _loadedServices[serviceName] == true;
  }

  /// Preload specific services (useful for predicted user flows)
  Future<void> preloadServices(List<String> serviceNames) async {
    await Future.wait(
      serviceNames.map((name) => loadService<void>(name)),
    );
  }

  /// Load Bible data (heavy operation)
  Future<void> _loadBibleData() async {
    try {
      final bibleService = Get.find<BibleService>();
      await bibleService.initialize((message) {
        if (kDebugMode) {
          print('Bible service lazy load: $message');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error lazy loading Bible service: $e');
      }
      rethrow;
    }
  }

  /// Load Daily Verse Controller
  Future<void> _loadDailyVerseController() async {
    if (!Get.isRegistered<DailyVerseController>()) {
      Get.put(DailyVerseController());
    }
  }

  /// Load History Controller
  Future<void> _loadHistoryController() async {
    if (!Get.isRegistered<HistoryController>()) {
      Get.put(HistoryController());
    }
  }

  /// Load Playlist Controller
  Future<void> _loadPlaylistController() async {
    if (!Get.isRegistered<PlaylistController>()) {
      Get.put(PlaylistController());
    }
  }

  /// Load Version Check Service
  Future<void> _loadVersionCheck() async {
    try {
      await VersionCheckService.checkForUpdateOnStartup();
    } catch (e) {
      if (kDebugMode) {
        print('Error lazy loading version check: $e');
      }
    }
  }

  /// Load Audio Mapping (network operation)
  Future<void> _loadAudioMapping() async {
    try {
      final audioMapping = AudioFileMapping();
      await audioMapping.updateAudioFileMapping();
    } catch (e) {
      if (kDebugMode) {
        print('Error lazy loading audio mapping: $e');
      }
    }
  }

  /// Load Firebase Sync Service
  Future<void> _loadFirebaseSync() async {
    if (!Get.isRegistered<FirebaseSyncService>()) {
      Get.put(FirebaseSyncService());
    }
  }

  /// Get all registered lazy services
  List<String> getRegisteredServices() {
    return _serviceLoaders.keys.toList();
  }

  /// Get loaded services status
  Map<String, bool> getLoadedServices() {
    return Map.unmodifiable(_loadedServices);
  }

  /// Reset all loaded services (for testing)
  void reset() {
    _loadedServices.clear();
  }
}

/// Extension methods for easy lazy service access
extension LazyServiceExtensions on LazyServiceManager {
  /// Get Bible Service (lazy loaded)
  Future<BibleService> get bibleService async => 
      await loadService<BibleService>('bible_data');

  /// Get Daily Verse Controller (lazy loaded)
  Future<DailyVerseController> get dailyVerseController async => 
      await loadService<DailyVerseController>('daily_verse');

  /// Get History Controller (lazy loaded)
  Future<HistoryController> get historyController async => 
      await loadService<HistoryController>('history');

  /// Get Playlist Controller (lazy loaded)
  Future<PlaylistController> get playlistController async => 
      await loadService<PlaylistController>('playlist');
}

/// Global lazy service manager instance
final lazyServiceManager = LazyServiceManager();