import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/hymn.dart';
import '../services/hymn_service.dart';

class HymnController extends GetxController {
  final HymnService _hymnService = HymnService();
  final searchController = TextEditingController();
  final favoriteStatuses = RxMap<String, String>({});

  @override
  void onInit() {
    super.onInit();
    loadFavoriteStatuses();
    _hymnService.checkPendingSyncs();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadFavoriteStatuses() async {
    try {
      final statuses = await _hymnService.getFavoriteStatusStream().first;
      favoriteStatuses.value = statuses;
    } catch (e) {
      debugPrint('Error loading favorite statuses: $e');
    }
  }

  Future<void> toggleFavorite(Hymn hymn) async {
    await _hymnService.toggleFavorite(hymn);
    await loadFavoriteStatuses();
  }

  Future<void> deleteHymn(Hymn hymn) async {
    await _hymnService.deleteHymn(hymn.id);
  }

  Stream<QuerySnapshot> get hymnsStream => _hymnService.getHymnsStream();

  List<Hymn> filterHymnList(List<DocumentSnapshot> docs) {
    List<Hymn> hymns = docs
        .map((doc) =>
            Hymn.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();

    hymns.sort(
        (a, b) => int.parse(a.hymnNumber).compareTo(int.parse(b.hymnNumber)));

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
}
