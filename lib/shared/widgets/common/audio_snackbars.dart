import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AudioSnackBar {
  static void showDownloading() {
    Get.snackbar(
      "Téléchargement de l'audio",
      "Récupération de l'enregistrement depuis Google Drive...",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  static void showDriveError(String message) {
    Get.snackbar(
      "Erreur d'accès à Drive",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFFFCDD2),
      colorText: const Color(0xFFC62828),
      duration: const Duration(seconds: 5),
    );
  }

  static void showPlaybackError(String message) {
    Get.snackbar(
      'Erreur de lecture',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withValues(alpha: 0.1),
      colorText: Colors.red,
      duration: const Duration(seconds: 4),
    );
  }

  static void showAudioNotAvailable() {
    Get.snackbar(
      'Audio indisponible',
      "Le fichier d'enregistrement est introuvable sur l'appareil ou dans Drive. Essayez d'abord de l'envoyer vers Drive.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.withValues(alpha: 0.1),
      colorText: Colors.orange,
    );
  }
}
