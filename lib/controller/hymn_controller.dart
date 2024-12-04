import 'dart:async';

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/hymn.dart';
import '../services/hymn_service.dart';

class HymnController extends GetxController {
  final searchController = TextEditingController();
  final _hymnService = HymnService();
  final favoriteStatuses = <String, String>{}.obs;
  StreamSubscription? _favoriteStatusSubscription;

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

  @override
  void onInit() {
    super.onInit();
    _initFavoriteStatusStream();
    _hymnService.checkPendingSyncs();
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

  @override
  void onClose() {
    searchController.dispose();
    _favoriteStatusSubscription?.cancel();
    super.onClose();
  }
}
