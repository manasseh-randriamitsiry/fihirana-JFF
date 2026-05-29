import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:fihirana/features/recording/data/services/google_drive_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fihirana/features/bible/domain/repositories/bible_repository.dart';
import 'package:fihirana/features/hymn/domain/repositories/hymn_repository.dart';
import 'package:fihirana/features/recording/data/services/recording_service.dart';
import 'package:fihirana/features/bible/data/services/bible_service.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/core/utils/translation_service.dart';
import 'package:fihirana/core/utils/translation_service_interface.dart';
import 'package:fihirana/core/utils/local_storage_service.dart';
import 'package:fihirana/features/admin/di/admin_di.dart';
import 'package:fihirana/features/recording/di/recording_di.dart';
import 'package:fihirana/features/announcement/di/announcement_di.dart';
import 'package:fihirana/features/audio/di/audio_di.dart';
import 'package:fihirana/features/bible/di/bible_di.dart';
import 'package:fihirana/features/hymn/di/hymn_di.dart';
import 'package:fihirana/features/auth/di/auth_di.dart';
import 'package:fihirana/features/contact/data/services/contact_service.dart';
import 'package:fihirana/features/contact/domain/repositories/i_contact_service.dart';
import 'package:fihirana/features/announcement/data/services/announcement_service.dart';
import 'package:fihirana/features/announcement/domain/repositories/i_announcement_service.dart';
import 'package:fihirana/features/daily_verse/data/services/daily_verse_service.dart';
import 'package:fihirana/features/daily_verse/domain/repositories/i_daily_verse_service.dart';
import 'package:fihirana/features/playlist/data/services/playlist_service.dart';
import 'package:fihirana/features/playlist/domain/repositories/i_playlist_service.dart';
import 'package:fihirana/features/bible/data/services/bible_highlight_service.dart';
import 'package:fihirana/features/bible/domain/repositories/i_bible_highlight_service.dart';
import 'package:fihirana/features/bible/data/services/note_service.dart';
import 'package:fihirana/features/bible/domain/repositories/i_note_service.dart';

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
    // Firebase Services
    Get.put<FirebaseFirestore>(FirebaseFirestore.instance);
    Get.put<firebase_auth.FirebaseAuth>(firebase_auth.FirebaseAuth.instance);
    final googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'https://www.googleapis.com/auth/contacts.readonly',
        'https://www.googleapis.com/auth/drive.file',
        'https://www.googleapis.com/auth/drive',
      ],
    );
    Get.put<GoogleSignIn>(googleSignIn);

    // Initialize Google Drive Service
    final driveService = GoogleDriveService();
    if (kDebugMode) {
      print('ServiceLocator: Creating GoogleDriveService instance');
      print(
          'ServiceLocator: Initializing GoogleDriveService with googleSignIn: $googleSignIn');
    }
    driveService.initialize(googleSignIn);
    Get.put<GoogleDriveService>(driveService);
    if (kDebugMode) {
      print(
          'ServiceLocator: GoogleDriveService initialized and registered with GetX');
      print(
          'ServiceLocator: Verifying GetX registration: ${Get.isRegistered<GoogleDriveService>()}');
    }

    // Storage Service
    final storageService = LocalStorageService();
    Get.put<LocalStorageService>(storageService);

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
    Get.put<IHymnService>(hymnService);

    // Register feature bindings without eagerly loading their data.
    RecordingDI.initialize();
    AdminDI.initialize();
    AnnouncementDI.init();
    AudioDI.init();
    BibleDI.init();
    HymnDI.init();
    AuthDI.init();
  }

  /// Register data services
  Future<void> _registerDataServices() async {
    // Contact Service
    final contactService = ContactService();
    Get.put<IContactService>(contactService);

    // Announcement Service
    final announcementService = AnnouncementService();
    Get.put<IAnnouncementService>(announcementService);

    // Daily Verse Service
    final dailyVerseService = DailyVerseService();
    Get.put<IDailyVerseService>(dailyVerseService);

    // Playlist Service
    final playlistService = PlaylistService();
    Get.put<IPlaylistService>(playlistService);

    // Bible Highlight Service
    final bibleHighlightService = BibleHighlightService();
    Get.put<IBibleHighlightService>(bibleHighlightService);

    // Note Service
    final noteService = NoteService();
    Get.put<INoteService>(noteService);
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
      return [
        'IRecordingService',
        'IBibleService',
        'ITranslationService',
        'IHymnService',
        'LocalStorageService',
        'RecordingRepository',
        'RecordingController',
        'AnnouncementController',
        'AnnouncementRepository',
        'AudioRepository',
        'AudioController',
        'BibleRepository',
        'BibleController',
        'HymnRepository',
        'HymnController',
        'AuthRepository',
        'AuthController'
      ];
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
  RecordingService get recordingService => getService<RecordingService>();

  /// Get Bible Service
  IBibleService get bibleService => getService<IBibleService>();

  /// Get Translation Service
  ITranslationService get translationService =>
      getService<ITranslationService>();

  /// Get Hymn Service
  IHymnService get hymnService => getService<IHymnService>();

  /// Get Storage Service
  LocalStorageService get storageService => getService<LocalStorageService>();

  /// Get Recording Controller (via DI)
  dynamic get recordingController => RecordingDI.recordingController;

  /// Get Recording Repository (via DI)
  dynamic get recordingRepository => RecordingDI.recordingRepository;
}

/// Global service locator instance
final serviceLocator = ServiceLocator();
