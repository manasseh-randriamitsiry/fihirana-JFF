import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SnackbarUtility {
  static void showError({
    required String title,
    required String message,
    Duration? duration,
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red.withOpacity(0.2),
      colorText: Colors.black,
      snackPosition: SnackPosition.BOTTOM,
      duration: duration ?? const Duration(seconds: 3),
      icon: const Icon(Icons.warning_amber, color: Colors.black),
    );
  }

  static void showSuccess({
    required String title,
    required String message,
    Duration? duration,
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green.withOpacity(0.2),
      colorText: Colors.black,
      snackPosition: SnackPosition.BOTTOM,
      duration: duration ?? const Duration(seconds: 3),
      icon: const Icon(Icons.check_circle, color: Colors.black),
    );
  }

  static void showInfo({
    required String title,
    required String message,
    Duration? duration,
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.blue.withOpacity(0.2),
      colorText: Colors.black,
      snackPosition: SnackPosition.BOTTOM,
      duration: duration ?? const Duration(seconds: 3),
      icon: const Icon(Icons.info, color: Colors.black),
    );
  }
} 