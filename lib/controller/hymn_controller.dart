import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fihirana/models/hymn.dart';
import 'package:fihirana/services/features/hymn_service.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class HymnController extends GetxController {
  late final TextEditingController searchController;
  final _hymnService = HymnService();
  final favoriteStatuses = <String, String>{}.obs;
  StreamSubscription? _favoriteStatusSubscription;
  bool _isDisposed = false;

  void _initFavoriteStatusStream() {
    _favoriteStatusSubscription?.cancel();
    _favoriteStatusSubscription = _hymnService.getFavoriteStatusStream().listen(
      (statuses) {
        favoriteStatuses.value = Map<String, String>.from(statuses);
      },
      onError: (e) {
        debugPrint('Error in favorite status stream: $e');
      },
    );
  }

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

  @override
  void onInit() {
    super.onInit();
    searchController = TextEditingController();
    _initFavoriteStatusStream();
  }

  Stream<Map<String, String>> getFavoriteStatusStream() {
    return _hymnService.getFavoriteStatusStream();
  }

  Future<void> toggleFavorite(Hymn hymn) async {
    await _hymnService.toggleFavorite(hymn);
  }

  Future<void> deleteHymn(Hymn hymn) async {
    await _hymnService.deleteHymn(hymn.id);
  }

  Stream<List<Hymn>> get hymnsStream => _hymnService.getLocalHymnsStream();

  Future<List<Hymn>> searchHymns(String query) async {
    return await _hymnService.searchHymns(query);
  }

  List<Hymn> filterHymnList(List<Hymn> hymns) {
    hymns.sort((a, b) {
      String numA = a.hymnNumber.replaceAll(RegExp(r'[^0-9]'), '');
      String numB = b.hymnNumber.replaceAll(RegExp(r'[^0-9]'), '');

      if (numA.isNotEmpty && numB.isNotEmpty) {
        return int.parse(numA).compareTo(int.parse(numB));
      }

      return a.hymnNumber.compareTo(b.hymnNumber);
    });

    final searchQuery = searchController.text.toLowerCase();
    if (searchQuery.isEmpty) return hymns;

    return hymns
        .where((hymn) =>
            hymn.hymnNumber.toLowerCase().contains(searchQuery) ||
            hymn.title.toLowerCase().contains(searchQuery) ||
            hymn.verses
                .any((verse) => verse.toLowerCase().contains(searchQuery)))
        .toList();
  }

  String getPreviewText(Hymn hymn) {
    if (hymn.verses.isEmpty) return '';
    final firstVerse = hymn.verses[0];
    if (firstVerse.length > 50) {
      return '${firstVerse.substring(0, 50)}...';
    }
    return firstVerse;
  }

  // Safe getter for search controller
  TextEditingController get safeSearchController {
    if (_isDisposed) {
      return TextEditingController();
    }
    return searchController;
  }

  // Check if controller is disposed
  bool get isDisposed => _isDisposed;

  @override
  void onClose() {
    _isDisposed = true;
    try {
      searchController.dispose();
    } catch (e) {
      // Controller already disposed, ignore
      if (kDebugMode) {
        debugPrint('SearchController already disposed: $e');
      }
    }
    _favoriteStatusSubscription?.cancel();
    super.onClose();
  }
}
