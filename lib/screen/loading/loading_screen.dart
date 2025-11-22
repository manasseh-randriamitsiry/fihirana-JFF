import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../controller/color_controller.dart';
import '../../models/hymn.dart';
import '../../services/local_storage_service.dart';
import '../accueil/home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double _progress = 0.0;
  String _currentTask = 'Manomboka...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _updateProgress(double progress, String task) {
    if (mounted) {
      setState(() {
        _progress = progress;
        _currentTask = task;
      });
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize storage (0% -> 30%)
      _updateProgress(0.0, 'Manomana ny fitahirizana...');
      print('Initializing storage service...');

      await _storageService.init().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Storage initialization timeout');
        },
      );

      _updateProgress(0.3, 'Fitahirizana vonona');
      print('Storage initialized');
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 2: Download Firebase hymns (30% -> 90%)
      _updateProgress(0.3, 'Maka ny hira avy amin\'ny Firebase...');
      print('Downloading Firebase hymns...');

      await _downloadFirebaseHymns(
        onProgress: (progress) {
          // Map 0.0-1.0 to 0.3-0.9
          _updateProgress(0.3 + (progress * 0.6),
              'Maka ny hira: ${(progress * 100).toInt()}%');
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Firebase download timeout');
        },
      );

      _updateProgress(0.9, 'Hira vita');
      print('Firebase hymns downloaded');
      await Future.delayed(const Duration(milliseconds: 300));

      // Step 3: Finalize (90% -> 100%)
      _updateProgress(0.95, 'Mamita...');
      await Future.delayed(const Duration(milliseconds: 500));

      _updateProgress(1.0, 'Vita!');
      print('Navigating to HomeScreen...');
      await Future.delayed(const Duration(milliseconds: 300));

      Get.off(() => const HomeScreen());
    } catch (e) {
      print('Error during initialization: $e');
      _updateProgress(1.0, 'Nisy olana, fa mandeha ihany...');
      await Future.delayed(const Duration(milliseconds: 500));
      Get.off(() => const HomeScreen());
    }
  }

  Future<void> _downloadFirebaseHymns({
    required Function(double) onProgress,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in, skipping Firebase hymns download');
        onProgress(1.0);
        return;
      }

      print('Fetching hymns from Firebase...');
      onProgress(0.2);

      final snapshot = await _firestore.collection('hymns').get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Firebase fetch timeout');
          throw TimeoutException('Firebase fetch timed out');
        },
      );

      onProgress(0.6);

      final firebaseHymns = snapshot.docs.map((doc) {
        final data = doc.data();
        return Hymn.fromJson(data, doc.id);
      }).toList();

      onProgress(0.8);

      if (firebaseHymns.isNotEmpty) {
        print('Saving ${firebaseHymns.length} hymns...');
        await _storageService.saveHymns(firebaseHymns);
        print('Hymns saved successfully');
      }

      onProgress(1.0);
    } catch (e) {
      print('Error downloading Firebase hymns: $e');
      onProgress(1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingAnimationWidget.staggeredDotsWave(
                color: colorController.primaryColor.value,
                size: 60,
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
                    backgroundColor:
                        colorController.primaryColor.value.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorController.primaryColor.value,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Percentage text
              Text(
                '${(_progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorController.primaryColor.value,
                    ),
              ),

              const SizedBox(height: 10),

              // Current task text
              Text(
                _currentTask,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorController.textColor.value.withOpacity(0.7),
                    ),
              ),

              const SizedBox(height: 40),

              Text(
                'Jesosy famonjena Fahamarinantsika',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
