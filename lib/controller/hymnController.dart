import 'package:get/get.dart';
import '../services/hymn_service.dart';
import 'package:flutter/material.dart';

class HymnController extends GetxController {
  var isDarkMode = false.obs;

  final HymnService _hymnService = HymnService();

  Future<bool> createHymn(String hymnNumber, String title, List<String> verses,
      String? bridge, String? hymnHint) async {

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