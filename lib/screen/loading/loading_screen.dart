import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../controller/color_controller.dart';
import '../../models/hymn.dart';
import '../../services/local_storage_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../accueil/home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxDouble _progress = 0.0.obs;
  final RxString _currentTask = 'Manomboka...'.obs;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _updateProgress(double progress, String task) {
    _progress.value = progress;
    _currentTask.value = task;
    print('Progress: ${(progress * 100).toInt()}% - $task');
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize storage (0% -> 30%)
      _updateProgress(0.0, 'Manomana ny fitahirizana...');
      await Future.delayed(const Duration(milliseconds: 200));

      print('Initializing storage service...');
      await _storageService.init().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Storage initialization timeout');
        },
      );

      _updateProgress(0.3, 'Fitahirizana vonona');
      print('Storage initialized');
      await Future.delayed(const Duration(milliseconds: 400));

      // Step 2: Download Firebase hymns (30% -> 90%)
      _updateProgress(0.35, 'Maka ny hira avy amin\'ny Firebase...');
      await Future.delayed(const Duration(milliseconds: 200));
      print('Downloading Firebase hymns...');

      await _downloadFirebaseHymns(
        onProgress: (progress) {
          // Map 0.0-1.0 to 0.35-0.9
          final mappedProgress = 0.35 + (progress * 0.55);
          _updateProgress(
            mappedProgress,
            'Maka ny hira: ${(progress * 100).toInt()}%',
          );
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Firebase download timeout');
        },
      );

      _updateProgress(0.9, 'Hira vita');
      print('Firebase hymns downloaded');
      await Future.delayed(const Duration(milliseconds: 400));

      // Step 3: Finalize (90% -> 100%)
      _updateProgress(0.95, 'Mamita...');
      await Future.delayed(const Duration(milliseconds: 400));

      _updateProgress(1.0, 'Vita!');
      print('Navigating to HomeScreen...');
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Get.off(() => const HomeScreen());
      }
    } catch (e) {
      print('Error during initialization: $e');
      _updateProgress(1.0, 'Nisy olana, fa mandeha ihany...');
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Get.off(() => const HomeScreen());
      }
    }
  }

  Future<void> _downloadFirebaseHymns({
    required Function(double) onProgress,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in, skipping Firebase hymns download');
        // Simulate progress for better UX
        for (int i = 0; i <= 10; i++) {
          onProgress(i / 10);
          await Future.delayed(const Duration(milliseconds: 50));
        }
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Obx(() {
            final colorController = Get.find<ColorController>();
            final primaryColor = colorController.primaryColor.value;
            final textColor = colorController.textColor.value;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rive Loading Animation
                // Loading Animation
                LoadingAnimationWidget.staggeredDotsWave(
                  color: primaryColor,
                  size: 100,
                ),

                const SizedBox(height: 40),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 8,
                    width: double.infinity,
                    child: LinearProgressIndicator(
                      value: _progress.value,
                      backgroundColor: primaryColor.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Percentage text
                Text(
                  '${(_progress.value * 100).toInt()}%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                ),

                const SizedBox(height: 10),

                // Current task text
                Text(
                  _currentTask.value,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textColor.withOpacity(0.7),
                      ),
                ),

                const SizedBox(height: 40),

                Text(
                  'Jesosy famonjena Fahamarinantsika',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
