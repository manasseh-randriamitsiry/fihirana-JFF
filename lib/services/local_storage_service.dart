import 'package:hive_flutter/hive_flutter.dart';
import '../models/hymn.dart';

class LocalStorageService {
  static const String hymnBoxName = 'hymns';
  static const String lastUpdateKey = 'last_update';
  late Box<Map> hymnBox;

  Future<void> init() async {
    await Hive.initFlutter();
    hymnBox = await Hive.openBox<Map>(hymnBoxName);
  }

  Future<void> saveHymns(List<Hymn> hymns) async {
    final batch = Map.fromEntries(
      hymns.map((hymn) => MapEntry(hymn.id, hymn.toMap())),
    );
    await hymnBox.putAll(batch);
    await hymnBox.put(lastUpdateKey, {'timestamp': DateTime.now().toIso8601String()});
  }

  List<Hymn> getLocalHymns() {
    final hymns = hymnBox.values
        .where((value) => value['hymnNumber'] != null)
        .toList();

    return hymns.map((data) {
      DateTime createdAt;
      try {
        createdAt = DateTime.parse(data['createdAt'] as String);
      } catch (e) {
        createdAt = DateTime.now();
      }

      return Hymn(
        id: data['id'] as String,
        hymnNumber: data['hymnNumber'] as String,
        title: data['title'] as String,
        verses: List<String>.from(data['verses'] as List),
        bridge: data['bridge'] as String?,
        hymnHint: data['hymnHint'] as String?,
        createdAt: createdAt,
        createdBy: data['createdBy'] as String,
        createdByEmail: data['createdByEmail'] as String?,
      );
    }).toList();
  }

  DateTime? getLastUpdate() {
    final lastUpdate = hymnBox.get(lastUpdateKey);
    if (lastUpdate != null && lastUpdate['timestamp'] != null) {
      return DateTime.parse(lastUpdate['timestamp'] as String);
    }
    return null;
  }

  Future<void> clearHymns() async {
    await hymnBox.clear();
  }

  Future<bool> hasLocalHymns() async {

    final hymnCount = hymnBox.values
        .where((value) => value['hymnNumber'] != null)
        .length;
    return hymnCount > 0;
  }

  Future<void> setLastUpdate(DateTime timestamp) async {
    await hymnBox.put(lastUpdateKey, {'timestamp': timestamp.toIso8601String()});
  }
}