import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/hymn.dart';
class LocalHymnService {
  static final LocalHymnService _instance = LocalHymnService._internal();
  factory LocalHymnService() => _instance;
  LocalHymnService._internal();

  final Map<String, Hymn> _hymnCache = {};
  List<Hymn>? _allHymns;

  Future<List<Hymn>> getAllHymns() async {
    if (_allHymns != null) {
      return _allHymns!;
    }

    try {

      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final List<Hymn> hymns = [];

      final jsonAssets = manifestMap.keys
          .where((key) => key.startsWith('assets/json/') && key.endsWith('.json'))
          .toList();

      for (final assetPath in jsonAssets) {
        try {
          final jsonString = await rootBundle.loadString(assetPath);
          final jsonData = json.decode(jsonString);

          final hymn = _parseHymnFromJson(jsonData, _extractIdFromPath(assetPath));
          hymns.add(hymn);
          _hymnCache[hymn.id] = hymn;
        } catch (e) {
        }
      }

      hymns.sort((a, b) {
        final numA = int.tryParse(a.hymnNumber) ?? 0;
        final numB = int.tryParse(b.hymnNumber) ?? 0;
        return numA.compareTo(numB);
      });

      _allHymns = hymns;
      return hymns;
    } catch (e) {
      return [];
    }
  }

  Future<Hymn?> getHymnById(String id) async {

    if (_hymnCache.containsKey(id)) {
      return _hymnCache[id];
    }

    try {

      final assetPath = 'assets/json/$id.json';
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonString);

      final hymn = _parseHymnFromJson(jsonData, id);
      _hymnCache[id] = hymn;
      return hymn;
    } catch (e) {
      return null;
    }
  }

  Hymn _parseHymnFromJson(Map<String, dynamic> jsonData, String id) {

    final List<String> verses = [];
    if (jsonData['verses'] is Map<String, dynamic>) {
      final versesMap = jsonData['verses'] as Map<String, dynamic>;

      final sortedKeys = versesMap.keys.toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

      for (final key in sortedKeys) {
        verses.add(versesMap[key].toString());
      }
    } else if (jsonData['verses'] is List) {
      verses.addAll(List<String>.from(jsonData['verses']));
    }

    if (jsonData['chorus'] != null) {
      verses.add(jsonData['chorus'].toString());
    }

    return Hymn(
      id: id,
      hymnNumber: jsonData['number'].toString(),
      title: jsonData['title'].toString(),
      verses: verses,
      bridge: jsonData['bridge']?.toString(),
      hymnHint: jsonData['hint']?.toString(),
      createdAt: DateTime.now(),
      createdBy: 'Local File',
    );
  }

  String _extractIdFromPath(String path) {
    final fileName = path.split('/').last;
    return fileName.substring(0, fileName.lastIndexOf('.'));
  }

  Future<List<Hymn>> searchHymns(String query) async {
    final allHymns = await getAllHymns();
    if (query.isEmpty) return allHymns;

    final lowerQuery = query.toLowerCase();
    return allHymns.where((hymn) {
      return hymn.hymnNumber.toLowerCase().contains(lowerQuery) ||
             hymn.title.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  void clearCache() {
    _hymnCache.clear();
    _allHymns = null;
  }
}