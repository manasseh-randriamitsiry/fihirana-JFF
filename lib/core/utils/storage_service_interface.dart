abstract class IStorageService {
  Future<void> initialize();
  Future<void> saveData<T>(String key, T data);
  T? getData<T>(String key);
  Future<void> removeData(String key);
  Future<void> clearAll();
  Future<void> setString(String key, String value);
  String? getString(String key);
  Future<void> setInt(String key, int value);
  int? getInt(String key);
  Future<void> setBool(String key, bool value);
  bool? getBool(String key);
  Future<void> setDouble(String key, double value);
  double? getDouble(String key);
  Future<void> setStringList(String key, List<String> value);
  List<String>? getStringList(String key);
}
