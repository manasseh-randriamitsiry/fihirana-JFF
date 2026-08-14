import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fihirana/features/auth/domain/usecases/sign_in_with_google_usecase.dart';

import 'package:fihirana/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:fihirana/features/auth/domain/usecases/ensure_user_document_exists_usecase.dart';
import 'package:fihirana/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fihirana/features/auth/data/services/google_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fihirana/core/security/security_service.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/app/theme/font_controller.dart';
import 'package:fihirana/core/localization/language_controller.dart';
import 'package:fihirana/app/theme/theme_controller.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/features/audio/data/services/hymn_audio_handler.dart';
import 'package:fihirana/features/audio/data/services/background_service.dart';
import 'package:fihirana/features/bible/data/services/bible_service.dart';
import 'package:fihirana/core/utils/firebase_sync_service.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/features/audio/data/services/local_audio_service.dart';
import 'package:fihirana/core/utils/notification_service.dart';
import 'package:fihirana/core/utils/deep_link_service.dart';
import 'package:fihirana/core/utils/version_check_service.dart';
import 'package:fihirana/core/init/lazy_service_manager.dart';
import 'package:fihirana/core/utils/background_isolate_manager.dart';
import 'package:fihirana/core/init/init_progress_tracker.dart';
import 'package:fihirana/core/controllers/user_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:async';

/// Initialization progress callback
typedef ProgressCallback = void Function(double progress, String currentStep);

class InitService {
  /// Initialize notifications
  static Future<void> initializeNotifications({
    ProgressCallback? onProgress,
  }) async {
    await NotificationService.initializeNotificationChannels();

    // Setup listeners for notification actions (e.g., audio player controls)
    // Note: Permission request is now handled in the welcome page during onboarding
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
    Get.put(UserController());
    // Initialize auth dependencies
    final authRepository = AuthRepositoryImpl(
      FirebaseAuthService(),
      FirebaseFirestore.instance,
      Get.find<GoogleSignIn>(),
      Get.find<SecurityService>(),
    );

    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(
        signInWithGoogleUseCase: SignInWithGoogleUseCase(authRepository),
        signOutUseCase: SignOutUseCase(authRepository),
        ensureUserDocumentExistsUseCase:
            EnsureUserDocumentExistsUseCase(authRepository),
      ));
    }

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
    // Recording controller is now initialized via DI in service_locator.dart

    // Initialize security service (critical - runs on app startup)
    Get.put(SecurityService());

    // Initialize Bible service (but don't load data yet)
    Get.put(BibleService());

    // Initialize lazy service manager
    lazyServiceManager.initialize();
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
    await HymnMediaSession.initialize(AudioService.instance);

    // Initialize local audio service (fast, just setup)
    final localAudioService = LocalAudioService();
    await localAudioService.initialize();

    // Defer audio mapping until a user actually opens audio-related screens.
    // This keeps startup lighter on low-end devices and avoids a network hit
    // before the first frame.
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

    // Audio mapping is now initialized in foreground during _initAudioServices()
    // to provide better error handling and user feedback

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
