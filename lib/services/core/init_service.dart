import 'package:fihirana/controller/auth_controller.dart';
import 'package:fihirana/controller/color_controller.dart';
import 'package:fihirana/controller/font_controller.dart';
import 'package:fihirana/controller/language_controller.dart';
import 'package:fihirana/controller/theme_controller.dart';
import 'package:fihirana/controller/shell_controller.dart';
import 'package:fihirana/controller/recording_controller.dart';
import 'package:fihirana/services/audio/audio_file_mapping.dart';
import 'package:fihirana/services/audio/audio_foreground_service.dart';
import 'package:fihirana/services/audio/background_service.dart';
import 'package:fihirana/services/features/bible_service.dart';
import 'package:fihirana/services/data/firebase_sync_service.dart';
import 'package:fihirana/services/features/hymn_service.dart';
import 'package:fihirana/services/audio/local_audio_service.dart';
import 'package:fihirana/services/core/notification_service.dart';
import 'package:fihirana/services/core/deep_link_service.dart';
import 'package:fihirana/services/core/version_check_service.dart';
import 'package:fihirana/services/core/security_service.dart';
import 'package:fihirana/services/core/lazy_service_manager.dart';
import 'package:fihirana/services/core/background_isolate_manager.dart';
import 'package:fihirana/services/core/init_progress_tracker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'dart:async';

/// Initialization progress callback
typedef ProgressCallback = void Function(double progress, String currentStep);

class InitService {
  /// Initialize notifications
  static Future<void> initializeNotifications({
    ProgressCallback? onProgress,
  }) async {
    await NotificationService.initializeNotificationChannels();

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    // Setup listeners for notification actions (e.g., audio player controls)
    NotificationService.setupNotificationListeners();
  }

  /// Initialize critical controllers needed for app startup
  static Future<void> initCriticalControllers({
    ProgressCallback? onProgress,
  }) async {
    // Initialize critical controllers first (needed for UI)
    final themeController = Get.put(ThemeController());
    final colorController = Get.put(ColorController());
    final fontController = Get.put(FontController());
    Get.put(LanguageController());
    Get.put(ShellController());
    Get.put(AuthController());

    // Load theme and colors (fast, from local storage)
    await Future.wait([
      colorController.loadColors(),
      themeController.loadThemeFromPrefs(),
    ]);

    // Initialize custom fonts before app starts using them
    await fontController.initializeCustomFonts();
  }

  /// Initialize non-critical controllers with lazy loading
  static Future<void> initNonCriticalControllers() async {
    // Initialize recording controller with minimal blocking
    Get.put(RecordingController(), permanent: true);

    // Initialize security service (critical - runs on app startup)
    Get.put(SecurityService());

    // Initialize Bible service (but don't load data yet)
    Get.put(BibleService());

    // Initialize lazy service manager
    lazyServiceManager.initialize();

    // Preload commonly used services based on user behavior patterns
    _preloadPredictedServices();
  }

  /// Preload services that are likely to be needed soon
  static void _preloadPredictedServices() {
    // Delay preloading to not block app startup
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        // Preload services that are commonly accessed
        await lazyServiceManager.preloadServices([
          'daily_verse', // Most users check daily verse
          'history',     // Recently accessed items
        ]);
      } catch (e) {
if (kDebugMode) {
        debugPrint('Error preloading services: $e');
      }
      }
    });
  }

  /// Initialize services with proper async handling
  static Future<void> initServices({
    ProgressCallback? onProgress,
  }) async {
    // Initialize services in parallel where possible
    await Future.wait([
      _initAudioServices(),
      _initDataServices(),
    ]);
  }

  static Future<void> _initAudioServices() async {
    Get.put(HymnService());
    Get.put(BackgroundService());
    Get.put(AudioForegroundService());
    
    // Initialize local audio service (fast, just setup)
    final localAudioService = LocalAudioService();
    await localAudioService.initialize();
  }

  static Future<void> _initDataServices() async {
    Get.put(FirebaseSyncService());
  }

  /// Initialize deep links
  static Future<void> initDeepLinks({
    ProgressCallback? onProgress,
  }) async {
    try {
      final deepLinkService = DeepLinkService();
      await deepLinkService.init();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing deep links: $e');
      }
    }
  }

  /// Complete app initialization with comprehensive progress tracking
  static Future<void> initializeApp({
    ProgressCallback? onProgress,
    Map<String, dynamic>? config,
  }) async {
    // Start progress tracking
    initProgressTracker.startTracking();
    
    // Listen to progress events and forward to callback
    StreamSubscription? progressSubscription;
    if (onProgress != null) {
      progressSubscription = initProgressTracker.progressStream.listen((event) {
        onProgress(event.progress, event.step.description);
      });
    }

    try {
      // Initialize notifications
      initProgressTracker.startStep('notifications');
      await initializeNotifications();
      initProgressTracker.completeStep('notifications');

      // Initialize critical controllers
      initProgressTracker.startStep('critical_controllers');
      await initCriticalControllers();
      initProgressTracker.completeStep('critical_controllers');

      // Initialize theme setup
      initProgressTracker.startStep('theme_setup');
      // Theme is already loaded in critical controllers
      initProgressTracker.completeStep('theme_setup');

      // Initialize font setup
      initProgressTracker.startStep('font_setup');
      // Fonts are already loaded in critical controllers
      initProgressTracker.completeStep('font_setup');

      // Initialize services
      initProgressTracker.startStep('audio_services');
      await _initAudioServices();
      initProgressTracker.completeStep('audio_services');

      initProgressTracker.startStep('data_services');
      await _initDataServices();
      initProgressTracker.completeStep('data_services');

      // Initialize non-critical controllers
      initProgressTracker.startStep('non_critical_controllers');
      await initNonCriticalControllers();
      initProgressTracker.completeStep('non_critical_controllers');

      // Security checks
      initProgressTracker.startStep('security_checks');
      // Security service is already initialized
      initProgressTracker.completeStep('security_checks');

      // Deep links
      initProgressTracker.startStep('deep_links');
      await initDeepLinks();
      initProgressTracker.completeStep('deep_links');

      // Background tasks
      initProgressTracker.startStep('background_tasks');
      _initializeBackgroundTasks();
      initProgressTracker.completeStep('background_tasks');

      // Lazy loading
      initProgressTracker.startStep('lazy_loading');
      // Lazy loading is already configured
      initProgressTracker.completeStep('lazy_loading');

      // Complete initialization
      initProgressTracker.complete();

    } catch (e) {
      final currentStep = initProgressTracker.currentStep;
      if (currentStep != null) {
        initProgressTracker.failStep(currentStep.id, e.toString());
      }
      
      if (kDebugMode) {
        debugPrint('Initialization failed: $e');
      }
      
      rethrow;
    } finally {
      await progressSubscription?.cancel();
    }
  }

  /// Initialize heavy operations in background isolates
  static void _initializeBackgroundTasks() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        // Initialize background isolate manager
        await backgroundIsolateManager.initialize();

        // Schedule heavy operations in background isolates
        unawaited(_scheduleBackgroundTasks());

if (kDebugMode) {
        debugPrint('Background tasks scheduled in isolates');
      }
      } catch (e) {
if (kDebugMode) {
        debugPrint('Error scheduling background tasks: $e');
      }
      }
    });
  }

  /// Schedule heavy background tasks
  static Future<void> _scheduleBackgroundTasks() async {
    // Schedule version check in background
    unawaited(
      backgroundIsolateManager.executeTask<void>(
        taskId: 'version_check',
        task: () async {
          await VersionCheckService.checkForUpdateOnStartup();
        },
        description: 'Check for app updates',
        priority: 1,
      ),
    );

    // Schedule audio mapping update in background
    unawaited(
      backgroundIsolateManager.executeTask<void>(
        taskId: 'audio_mapping_update',
        task: () async {
          final audioMapping = AudioFileMapping();
          await audioMapping.updateAudioFileMapping();
        },
        description: 'Update audio file mapping',
        priority: 2,
        isCancellable: true,
      ),
    );

    // Schedule Bible service initialization in background
    unawaited(
      backgroundIsolateManager.executeTask<void>(
        taskId: 'bible_service_init',
        task: () async {
          final bibleService = Get.find<BibleService>();
          await bibleService.initialize((message) {
if (kDebugMode) {
          debugPrint('Bible service (isolate): $message');
        }
          });
        },
        description: 'Initialize Bible service data',
        priority: 3,
      ),
    );
  }
}

/// Helper function to unawait futures
void unawaited(Future<void> future) {
  // Intentionally not awaiting the future
}