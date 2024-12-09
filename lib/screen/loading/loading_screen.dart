import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../services/download_manager.dart';
import '../../services/local_storage_service.dart';
import '../accueil/home_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final LocalStorageService _storageService = LocalStorageService();
  late DownloadManager _downloadManager;
  double _progress = 0;
  String? _error;
  bool _showRetry = false;

  @override
  void initState() {
    super.initState();
    _downloadManager = DownloadManager(storageService: _storageService);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _storageService.init();
      await _downloadManager.initNotifications();

      // Check if we need to download hymns
      final hasUpdates = await _downloadManager.checkForUpdates();
      if (hasUpdates) {
        await _downloadManager.downloadHymns(
          onProgress: (progress) {
            setState(() {
              _progress = progress;
            });
          },
          onError: (error) {
            setState(() {
              _error = error;
              // Show error snackbar
              Get.snackbar(
                'Nisy olana',
                error,
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
                duration: const Duration(seconds: 5),
              );
            });
          },
        );
      }

      // Even if download fails, try to load cached hymns
      final hasLocalHymns = await _storageService.hasLocalHymns();
      if (hasLocalHymns) {
        Get.off(() => const HomeScreen());
      } else if (_error != null) {
        // If we have no local hymns and download failed, show retry button
        setState(() {
          _showRetry = true;
        });
      } else {
        Get.off(() => const HomeScreen());
      }
    } catch (e) {
      print('Initialization error: $e');
      setState(() {
        _error = e.toString();
        _showRetry = true;
      });
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
              color: Theme.of(context).colorScheme.primary,
              size: 60,
            ),
            const SizedBox(height: 30),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      'Error: $_error',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    if (_showRetry)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _showRetry = false;
                            _progress = 0;
                          });
                          _initializeApp();
                        },
                        child: const Text('Averina atao'),
                      ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Text(
                    'Mijery hira vaovao...',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 200,
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
