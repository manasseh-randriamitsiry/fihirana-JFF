import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthSnackBar {
  static void showEmailAlreadyInUse() {
    Get.snackbar(
      'The email address is already in use.',
      'Try another email address.',
      backgroundColor: Colors.red.withValues(alpha: 0.2),
      colorText: Colors.black,
      icon: const Icon(Icons.warning_amber, color: Colors.black),
    );
  }

  static void showInvalidCredentials() {
    Get.snackbar(
      'Invalid credentials',
      'The email address is already in use.',
      backgroundColor: Colors.red.withValues(alpha: 0.2),
      colorText: Colors.black,
      icon: const Icon(Icons.warning_amber, color: Colors.black),
    );
  }
}
