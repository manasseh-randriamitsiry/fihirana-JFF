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

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('Initializing storage service...');
      await _storageService.init().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Storage initialization timeout');
        },
      );
      print('Storage initialized');

      print('Downloading Firebase hymns...');
      await _downloadFirebaseHymns().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Firebase download timeout');
        },
      );
      print('Firebase hymns downloaded');

      print('Navigating to HomeScreen...');
      await Future.delayed(const Duration(milliseconds: 500));
      Get.off(() => const HomeScreen());
    } catch (e) {
      print('Error during initialization: $e');
      await Future.delayed(const Duration(milliseconds: 500));
      Get.off(() => const HomeScreen());
    }
  }

  Future<void> _downloadFirebaseHymns() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in, skipping Firebase hymns download');
        return;
      }

      print('Fetching hymns from Firebase...');
      final snapshot = await _firestore.collection('hymns').get().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Firebase fetch timeout');
          throw TimeoutException('Firebase fetch timed out');
        },
      );

      final firebaseHymns = snapshot.docs.map((doc) {
        final data = doc.data();
        return Hymn.fromJson(data, doc.id);
      }).toList();

      if (firebaseHymns.isNotEmpty) {
        print('Saving ${firebaseHymns.length} hymns...');
        await _storageService.saveHymns(firebaseHymns);
        print('Hymns saved successfully');
      }
    } catch (e) {
      print('Error downloading Firebase hymns: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingAnimationWidget.staggeredDotsWave(
              color: Get.find<ColorController>().primaryColor.value,
              size: 60,
            ),
            const SizedBox(height: 30),
            Text(
              'Jesosy famonjena Fahamarinantsika',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
