import 'package:fihirana/app.dart';
import 'package:fihirana/firebase_options.dart';
import 'package:fihirana/services/init_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rive/rive.dart';

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Minimum delay to show the splash screen
    final minDelay = Future.delayed(const Duration(seconds: 2));

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Notifications
    await InitService.initializeNotifications();

    // Initialize Controllers and Services
    await InitService.initControllers();

    // Get SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // Wait for minimum delay
    await minDelay;

    if (mounted) {
      runApp(
        Phoenix(
          child: MyApp(prefs: prefs),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SizedBox(
            width: 250,
            height: 250,
            child: RiveAnimation.asset(
              'assets/animations/loading.riv',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
