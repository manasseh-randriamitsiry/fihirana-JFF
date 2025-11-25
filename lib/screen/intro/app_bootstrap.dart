import 'package:fihirana/app.dart';
import 'package:fihirana/firebase_options.dart';
import 'package:fihirana/services/init_service.dart';
import 'package:fihirana/services/security_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  double _progress = 0.0;
  final String _currentTask = '...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _updateProgress(double progress) {
    if (mounted) {
      setState(() {
        _progress = progress;
      });
    }
  }

  Future<void> _initialize() async {
    try {
      // Step 1: Initialize Firebase (0% -> 40%)
      _updateProgress(0.0);

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _updateProgress(0.4);

      // Step 2: Initialize Notifications (40% -> 60%)
      _updateProgress(0.4);

      await InitService.initializeNotifications();

      _updateProgress(0.6);

      // Step 3: Initialize Controllers (60% -> 90%)
      _updateProgress(0.6);

      await InitService.initControllers();

      _updateProgress(0.9);

      // Initialize deep links for playlist sharing
      await InitService.initDeepLinks();

      // Step 4: Security Check (90% -> 95%)
      _updateProgress(0.9);
      
      // Security check will run automatically when SecurityService is initialized
      // This ensures blocked users are handled before app fully loads
      await Future.delayed(const Duration(milliseconds: 500)); // Allow security check to complete

      // Step 5: Get SharedPreferences (95% -> 100%)
      _updateProgress(0.95);

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

      _updateProgress(1.0);

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
      }
      _updateProgress(1.0);
      await Future.delayed(const Duration(milliseconds: 300));

      // Try to continue anyway
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        runApp(
          Phoenix(
            child: MyApp(prefs: prefs),
          ),
        );
      }
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
