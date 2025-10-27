import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../controller/color_controller.dart';
import '../../services/local_storage_service.dart';
import '../accueil/home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _storageService.init();
      
      // Skip Firebase download entirely and go directly to home screen
      // All hymns are now loaded from local JSON files
      Get.off(() => const HomeScreen());
    } catch (e) {
      print('Initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading animation
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