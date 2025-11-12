import 'package:get/get.dart';
import '../services/hymn_service.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class HymnController extends GetxController {
  var isDarkMode = false.obs;

  final HymnService _hymnService = HymnService();

  Future<bool> createHymn(String hymnNumber, String title, List<String> verses,
      String? bridge, String? hymnHint) async {
    final l10n = AppLocalizations.of(Get.context!)!;
    Get.snackbar(
      l10n.noPermission,
      l10n.cannotAddHymns,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    return false;
  }
}
