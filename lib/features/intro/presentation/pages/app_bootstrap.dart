import 'package:fihirana/app.dart';
import 'package:fihirana/firebase_options.dart';
import 'package:fihirana/core/init/init_service.dart';
import 'package:fihirana/core/di/service_locator.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fihirana/features/auth/domain/usecases/sign_in_with_google_usecase.dart';

import 'package:fihirana/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:fihirana/features/auth/domain/usecases/ensure_user_document_exists_usecase.dart';
import 'package:fihirana/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fihirana/features/auth/data/services/google_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fihirana/core/security/security_service.dart';
import 'package:fihirana/core/init/init_progress_tracker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'dart:async';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  double _progress = 0.0;
  String _currentTask = 'Initializing app...';
  StreamSubscription<InitProgressEvent>? _progressSubscription;

@override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }



Future<void> _initialize() async {
    try {
      // Listen to detailed progress events
      _progressSubscription = initProgressTracker.progressStream.listen((event) {
        if (mounted) {
          setState(() {
            _progress = event.progress;
            _currentTask = event.step.description;
          });
        }
      });

      // Step 1: Initialize Firebase (0% -> 20%)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Step 2: Ensure minimal controllers required by services are registered,
      // then initialize Service Locator (20% -> 30%)
      try {
        if (!Get.isRegistered<AuthController>()) {
          // Initialize auth dependencies
          final authRepository = AuthRepositoryImpl(
            FirebaseAuthService(),
            FirebaseFirestore.instance,
            GoogleSignIn(),
            Get.isRegistered<SecurityService>() ? Get.find<SecurityService>() : SecurityService(),
          );
          
          Get.put(AuthController(
            signInWithGoogleUseCase: SignInWithGoogleUseCase(authRepository),
            signOutUseCase: SignOutUseCase(authRepository),
            ensureUserDocumentExistsUseCase: EnsureUserDocumentExistsUseCase(authRepository),
          ));
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error pre-registering AuthController: $e');
        }
      }

      await serviceLocator.initialize();

      // Step 3: Initialize App with Comprehensive Progress Tracking (30% -> 90%)
      await InitService.initializeApp();

      // Step 4: Get SharedPreferences (90% -> 95%)
      final prefs = await SharedPreferences.getInstance();

      // Track installation
      try {
        final isFirstRun = prefs.getBool('first_run') ?? true;
        if (isFirstRun) {
          await FirebaseFirestore.instance
              .collection('stats')
              .doc('global')
              .set({
            'installations': FieldValue.increment(1),
          }, SetOptions(merge: true));
          await prefs.setBool('first_run', false);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error tracking installation: $e');
        }
      }

      // Step 5: Final security check (95% -> 100%)
      // Allow security service to complete its checks
      await Future.delayed(const Duration(milliseconds: 500));

      // Small delay to show completion
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        runApp(
          Phoenix(
            child: MyApp(prefs: prefs),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during bootstrap: $e');
        print('Initialization summary: ${initProgressTracker.getSummary()}');
      }
      
      // Try to continue anyway
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        runApp(
          Phoenix(
            child: MyApp(prefs: prefs),
          ),
        );
      }
    } finally {
      await _progressSubscription?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 400 : double.infinity,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Loading Animation
                  LoadingAnimationWidget.staggeredDotsWave(
                    color: Colors.blue,
                    size: isTablet ? 60 : 100,
                  ),

                  SizedBox(height: isTablet ? 30 : 40),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: 8,
                      width: double.infinity,
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.blue.withValues(alpha: 0.2),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  ),

                  SizedBox(height: isTablet ? 15 : 20),

                  // Percentage text
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: isTablet ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Current task text
                  Text(
                    _currentTask,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
