import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AudioSnackBar {
  static void showDownloading() {
    Get.snackbar(
      'Downloading Audio',
      'Fetching recording from Google Drive...',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  static void showDriveError(String message) {
    Get.snackbar(
      'Drive Access Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFFFCDD2),
      colorText: const Color(0xFFC62828),
      duration: const Duration(seconds: 5),
    );
  }

  static void showPlaybackError(String message) {
    Get.snackbar(
      'Playback Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withValues(alpha: 0.1),
      colorText: Colors.red,
      duration: const Duration(seconds: 4),
    );
  }

  static void showAudioNotAvailable() {
    Get.snackbar(
      'Audio Not Available',
      'Recording file not found locally or on Drive. Try uploading to Drive first.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.withValues(alpha: 0.1),
      colorText: Colors.orange,
    );
  }
}