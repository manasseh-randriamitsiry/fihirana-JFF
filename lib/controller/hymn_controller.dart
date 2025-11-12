import 'dart:async';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../models/hymn.dart';
import '../services/hymn_service.dart';

class HymnController extends GetxController {
  final searchController = TextEditingController();
  final _hymnService = HymnService();
  final favoriteStatuses = <String, String>{}.obs;
  StreamSubscription? _favoriteStatusSubscription;
  static HymnController? _instance;

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

  factory HymnController() {
    _instance ??= HymnController._();
    return _instance!;
  }

  HymnController._() : super();

  @override
  void onInit() {
    super.onInit();
    _initFavoriteStatusStream();
    _loadHymns();
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

  List<Hymn> _sortedHymns = [];
  List<Hymn> _allHymns = [];
  bool _loaded = false;
  
  Future<void> _loadHymns() async {
    if (_loaded) return;
    
    try {
      _allHymns = await _hymnService.getLocalHymnsStream().first;
      _sortedHymns = List<Hymn>.from(_allHymns);
      _sortedHymns.sort((a, b) {
        String numA = a.hymnNumber.replaceAll(RegExp(r'[^0-9]'), '');
        String numB = b.hymnNumber.replaceAll(RegExp(r'[^0-9]'), '');

        if (numA.isNotEmpty && numB.isNotEmpty) {
          return int.parse(numA).compareTo(int.parse(numB));
        }

        return a.hymnNumber.compareTo(b.hymnNumber);
      });
      _loaded = true;
      update();
    } catch (e) {
      _allHymns = [];
      _sortedHymns = [];
      _loaded = true;
    }
  }
  
  List<Hymn> filterHymnList(List<Hymn> hymns) {
    if (!_loaded) {
      _loadHymns();
      return [];
    }

    final searchQuery = searchController.text.toLowerCase().trim();
    if (searchQuery.isEmpty) return _sortedHymns;

    return _sortedHymns
        .where((hymn) =>
            hymn.hymnNumber.toLowerCase().contains(searchQuery) ||
            hymn.title.toLowerCase().contains(searchQuery))
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