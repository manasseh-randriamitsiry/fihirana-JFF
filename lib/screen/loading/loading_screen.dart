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
      await _storageService.init();

      await _downloadFirebaseHymns();

      Get.off(() => const HomeScreen());
    } catch (e) {

      Get.off(() => const HomeScreen());
    }
  }

  Future<void> _downloadFirebaseHymns() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await _firestore.collection('hymns').get();

      final firebaseHymns = snapshot.docs.map((doc) {
        final data = doc.data();
        return Hymn.fromJson(data, doc.id);
      }).toList();

      if (firebaseHymns.isNotEmpty) {
        await _storageService.saveHymns(firebaseHymns);
      }
    } catch (e) {

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