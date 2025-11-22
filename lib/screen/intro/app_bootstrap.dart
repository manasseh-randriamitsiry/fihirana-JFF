import 'package:fihirana/app.dart';
import 'package:fihirana/firebase_options.dart';
import 'package:fihirana/services/init_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/rive_animation_widget.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  double _progress = 0.0;
  String _currentTask = '...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _updateProgress(double progress, String task) {
    if (mounted) {
      setState(() {
        _progress = progress;
        _currentTask = task;
      });
    }
  }

  Future<void> _initialize() async {
    try {
      // Step 1: Initialize Firebase (0% -> 40%)
      _updateProgress(0.0, 'Firebase...');

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _updateProgress(0.4, 'Firebase vonona');

      // Step 2: Initialize Notifications (40% -> 60%)
      _updateProgress(0.4, 'Notification ...');

      await InitService.initializeNotifications();

      _updateProgress(0.6, 'Notification vonona');

      // Step 3: Initialize Controllers (60% -> 90%)
      _updateProgress(0.6, 'Controllers...');

      await InitService.initControllers();

      _updateProgress(0.9, 'Controllers vonona');

      // Step 4: Get SharedPreferences (90% -> 100%)
      _updateProgress(0.9, 'Mamarana...');

      final prefs = await SharedPreferences.getInstance();

      _updateProgress(1.0, '');

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
      print('Error during bootstrap: $e');
      _updateProgress(1.0, 'Nisy olana, fa mandeha ihany...');
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rive Loading Animation
                const RiveAnimationWidget(
                  assetPath: 'assets/animations/loading.riv',
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 40),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 8,
                    width: double.infinity,
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Percentage text
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 32,
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
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
