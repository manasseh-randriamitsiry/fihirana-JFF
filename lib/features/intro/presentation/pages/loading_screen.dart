import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/core/utils/local_storage_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:fihirana/features/home/presentation/pages/home_screen.dart';

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
    if (kDebugMode) {
      print('Progress: ${(progress * 100).toInt()}% - $task');
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize storage (0% -> 30%)
      _updateProgress(0.0, 'Manomana ny fitahirizana...');

      await _storageService.init().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          if (kDebugMode) {}
        },
      );

      _updateProgress(0.3, 'Fitahirizana vonona');

      // Step 2: Download Firebase hymns (30% -> 90%)
      _updateProgress(0.35, 'Maka ny hira avy amin\'ny Firebase...');

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
          if (kDebugMode) {}
        },
      );

      _updateProgress(0.9, 'Hira vita');

      // Step 3: Finalize (90% -> 100%)
      _updateProgress(0.95, 'Mamita...');

      _updateProgress(1.0, 'Vita!');

      if (mounted) {
        Get.off(() => const HomeScreen());
      }
    } catch (e) {
      _updateProgress(1.0, 'Nisy olana, fa mandeha ihany...');
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
        // Keep the logged-out path fast; only emit a few coarse updates.
        for (final progress in const [0.25, 0.6, 1.0]) {
          onProgress(progress);
          await Future.delayed(const Duration(milliseconds: 20));
        }
        return;
      }

      onProgress(0.2);

      final snapshot = await _firestore.collection('hymns').get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
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
        await _storageService.saveHymns(firebaseHymns);
      }

      onProgress(1.0);
    } catch (e) {
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
            final colorScheme = Theme.of(context).colorScheme;
            final primaryColor = colorScheme.primary;
            final textColor = colorScheme.onSurface;

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
                      backgroundColor: primaryColor.withValues(alpha: 0.2),
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
                      ),
                ),

                const SizedBox(height: 10),

                // Current task text
                Text(
                  _currentTask.value,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textColor.withValues(alpha: 0.7),
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
