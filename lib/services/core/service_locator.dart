import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../interfaces/irecording_service.dart';
import '../interfaces/ibible_service.dart';
import '../interfaces/itranslation_service.dart';
import '../interfaces/ihymn_service.dart';
import '../interfaces/istorage_service.dart';
import '../audio/recording_service.dart';
import '../features/bible_service.dart';
import '../core/translation_service.dart';
import '../features/hymn_service.dart';
import '../data/local_storage_service.dart';

/// Service locator for dependency injection
/// This provides a centralized way to manage service instances and their dependencies
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  bool _isInitialized = false;

  /// Initialize all services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Register core services first
      await _registerCoreServices();
      
      // Register feature services
      await _registerFeatureServices();
      
      // Register data services
      await _registerDataServices();
      
      _isInitialized = true;
      if (kDebugMode) print('✅ ServiceLocator initialized successfully');
    } catch (e) {
      if (kDebugMode) print('❌ Failed to initialize ServiceLocator: $e');
      rethrow;
    }
  }

  /// Register core services
  Future<void> _registerCoreServices() async {
    // Storage Service
    final storageService = LocalStorageService();
    Get.put<IStorageService>(storageService);
    
    // Translation Service
    final translationService = TranslationService();
    await translationService.initialize();
    Get.put<ITranslationService>(translationService);
  }

  /// Register feature services
  Future<void> _registerFeatureServices() async {
    // Bible Service
    final bibleService = BibleService();
    Get.put<IBibleService>(bibleService);
    
    // Hymn Service
    final hymnService = HymnService();
    await hymnService.initialize();
    Get.put<IHymnService>(hymnService);
    
    // Recording Service
    final recordingService = RecordingService();
    await recordingService.initialize();
    Get.put<IRecordingService>(recordingService);
  }

  /// Register data services
  Future<void> _registerDataServices() async {
    // Additional data services can be registered here
  }

  /// Get service by type
  T getService<T>() {
    if (!Get.isRegistered<T>()) {
      throw Exception('Service of type $T is not registered');
    }
    return Get.find<T>();
  }

  /// Register a service instance
  void registerService<T>(T service) {
    if (Get.isRegistered<T>()) {
      Get.replace<T>(service);
    } else {
      Get.put<T>(service);
    }
  }

  /// Register a service instance with tag
  void registerServiceWithTag<T>(T service, String tag) {
    if (Get.isRegistered<T>(tag: tag)) {
      Get.replace<T>(service, tag: tag);
    } else {
      Get.put<T>(service, tag: tag);
    }
  }

  /// Get service by type and tag
  T getServiceWithTag<T>(String tag) {
    if (!Get.isRegistered<T>(tag: tag)) {
      throw Exception('Service of type $T with tag $tag is not registered');
    }
    return Get.find<T>(tag: tag);
  }

  /// Check if service is registered
  bool isServiceRegistered<T>() {
    return Get.isRegistered<T>();
  }

  /// Check if service is registered with tag
  bool isServiceRegisteredWithTag<T>(String tag) {
    return Get.isRegistered<T>(tag: tag);
  }

  /// Remove a service
  void removeService<T>() {
    if (Get.isRegistered<T>()) {
      Get.delete<T>();
    }
  }

  /// Remove a service with tag
  void removeServiceWithTag<T>(String tag) {
    if (Get.isRegistered<T>(tag: tag)) {
      Get.delete<T>(tag: tag);
    }
  }

  /// Reset all services (for testing)
  void reset() {
    Get.reset();
    _isInitialized = false;
  }

  /// Get all registered services
  List<String> getRegisteredServices() {
    try {
      // Return a simple list since getAllDependencies is not available
      return ['IRecordingService', 'IBibleService', 'ITranslationService', 'IHymnService', 'IStorageService'];
    } catch (e) {
      return [];
    }
  }

  /// Check if initialized
  bool get isInitialized => _isInitialized;
}

/// Extension methods for easy service access
extension ServiceLocatorExtensions on ServiceLocator {
  /// Get Recording Service
  IRecordingService get recordingService => getService<IRecordingService>();
  
  /// Get Bible Service
  IBibleService get bibleService => getService<IBibleService>();
  
  /// Get Translation Service
  ITranslationService get translationService => getService<ITranslationService>();
  
  /// Get Hymn Service
  IHymnService get hymnService => getService<IHymnService>();
  
  /// Get Storage Service
  IStorageService get storageService => getService<IStorageService>();
}

/// Global service locator instance
final serviceLocator = ServiceLocator();