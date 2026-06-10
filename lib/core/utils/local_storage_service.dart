import 'package:fihirana/core/utils/storage_info.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';

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
    await hymnBox
        .put(lastUpdateKey, {'timestamp': DateTime.now().toIso8601String()});
  }

  List<Hymn> getLocalHymns() {
    final hymns =
        hymnBox.values.where((value) => value['hymnNumber'] != null).toList();

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
    final hymnCount =
        hymnBox.values.where((value) => value['hymnNumber'] != null).length;
    return hymnCount > 0;
  }

  Future<void> setLastUpdate(DateTime timestamp) async {
    await hymnBox
        .put(lastUpdateKey, {'timestamp': timestamp.toIso8601String()});
  }

  Future<void> initialize() async {
    await init();
  }

  Future<void> saveData<T>(String key, T data) async {
    if (data is Map) {
      await hymnBox.put(key, data);
    } else {
      await hymnBox.put(key, {'value': data});
    }
  }

  Future<T?> getData<T>(String key) async {
    return hymnBox.get(key) as T?;
  }

  Future<void> removeData(String key) async {
    await hymnBox.delete(key);
  }

  Future<void> clearAll() async {
    await hymnBox.clear();
  }

  Future<bool> containsKey(String key) async {
    return hymnBox.containsKey(key);
  }

  Future<List<String>> getAllKeys() async {
    return hymnBox.keys.cast<String>().toList();
  }

  Future<void> setString(String key, String value) async {
    await hymnBox.put(key, {'value': value});
  }

  Future<String?> getString(String key) async {
    final data = hymnBox.get(key);
    if (data is Map && data.containsKey('value')) {
      return data['value'] as String?;
    }
    return data as String?;
  }

  Future<void> setInt(String key, int value) async {
    await hymnBox.put(key, {'value': value});
  }

  Future<int?> getInt(String key) async {
    final data = hymnBox.get(key);
    if (data is Map && data.containsKey('value')) {
      return data['value'] as int?;
    }
    return data as int?;
  }

  Future<void> setBool(String key, bool value) async {
    await hymnBox.put(key, {'value': value});
  }

  Future<bool?> getBool(String key) async {
    final data = hymnBox.get(key);
    if (data is Map && data.containsKey('value')) {
      return data['value'] as bool?;
    }
    return data as bool?;
  }

  Future<void> setDouble(String key, double value) async {
    await hymnBox.put(key, {'value': value});
  }

  Future<double?> getDouble(String key) async {
    final data = hymnBox.get(key);
    if (data is Map && data.containsKey('value')) {
      return data['value'] as double?;
    }
    return data as double?;
  }

  Future<void> setStringList(String key, List<String> value) async {
    await hymnBox.put(key, {'value': value});
  }

  Future<List<String>?> getStringList(String key) async {
    final data = hymnBox.get(key);
    if (data is Map && data.containsKey('value')) {
      return data['value'] as List<String>?;
    }
    return data as List<String>?;
  }

  Future<StorageInfo> getStorageInfo() async {
    final keys = await getAllKeys();
    final itemCount = keys.length;
    // Simplified storage calculation
    final usedBytes = itemCount * 1024; // Estimate 1KB per item
    const totalBytes = 100 * 1024 * 1024; // 100MB estimate
    final freeBytes = totalBytes - usedBytes;

    return StorageInfo(
      totalBytes: totalBytes,
      usedBytes: usedBytes,
      freeBytes: freeBytes,
      itemCount: itemCount,
    );
  }

  Future<void> compress() async {
    // Hive automatically compacts, no action needed
  }

  Future<void> backup(String backupPath) async {
    // Implementation would depend on backup strategy
    throw UnimplementedError('Backup not implemented');
  }

  Future<void> restore(String backupPath) async {
    // Implementation would depend on restore strategy
    throw UnimplementedError('Restore not implemented');
  }
}
