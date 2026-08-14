import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthSnackBar {
  static void showEmailAlreadyInUse() {
    Get.snackbar(
      "Cette adresse e-mail est déjà utilisée.",
      'Essayez une autre adresse e-mail.',
      backgroundColor: Colors.red.withValues(alpha: 0.2),
      colorText: Colors.black,
      icon: const Icon(Icons.warning_amber, color: Colors.black),
    );
  }

  static void showInvalidCredentials() {
    Get.snackbar(
      'Identifiants invalides',
      "Cette adresse e-mail est déjà utilisée.",
      backgroundColor: Colors.red.withValues(alpha: 0.2),
      colorText: Colors.black,
      icon: const Icon(Icons.warning_amber, color: Colors.black),
    );
  }
}
