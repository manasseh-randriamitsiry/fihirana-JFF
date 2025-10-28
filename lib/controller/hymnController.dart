import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/hymn.dart';
import '../services/hymn_service.dart';
import 'package:flutter/material.dart';

class HymnController extends GetxController {
  var isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  final HymnService _hymnService = HymnService();

  Future<bool> createHymn(String hymnNumber, String title, List<String> verses,
      String? bridge, String? hymnHint) async {
    // Since we've disabled Firestore, we can no longer add hymns
    // This functionality is not available with local files only
    Get.snackbar(
      'Tsy mananana alalana',
      'Tsy afaka manampy hira amin\'izao fotoana izao',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    return false;
  }
}