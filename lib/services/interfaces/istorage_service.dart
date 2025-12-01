/// Abstract interface for Storage service operations
/// This allows for dependency injection and better testability
abstract class IStorageService {
  /// Initialize the storage service
  Future<void> initialize();
  
  /// Save data to local storage
  Future<void> saveData<T>(String key, T data);
  
  /// Retrieve data from local storage
  Future<T?> getData<T>(String key);
  
  /// Remove data from local storage
  Future<void> removeData(String key);
  
  /// Clear all data from local storage
  Future<void> clearAll();
  
  /// Check if key exists
  Future<bool> containsKey(String key);
  
  /// Get all keys
  Future<List<String>> getAllKeys();
  
  /// Save string data
  Future<void> setString(String key, String value);
  
  /// Get string data
  Future<String?> getString(String key);
  
  /// Save integer data
  Future<void> setInt(String key, int value);
  
  /// Get integer data
  Future<int?> getInt(String key);
  
  /// Save boolean data
  Future<void> setBool(String key, bool value);
  
  /// Get boolean data
  Future<bool?> getBool(String key);
  
  /// Save double data
  Future<void> setDouble(String key, double value);
  
  /// Get double data
  Future<double?> getDouble(String key);
  
  /// Save string list
  Future<void> setStringList(String key, List<String> value);
  
  /// Get string list
  Future<List<String>?> getStringList(String key);
  
  /// Get storage usage information
  Future<StorageInfo> getStorageInfo();
  
  /// Compress storage if needed
  Future<void> compress();
  
  /// Backup storage data
  Future<void> backup(String backupPath);
  
  /// Restore storage data from backup
  Future<void> restore(String backupPath);
}

/// Storage usage information
class StorageInfo {
  final int totalBytes;
  final int usedBytes;
  final int freeBytes;
  final int itemCount;
  
  StorageInfo({
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
    required this.itemCount,
  });
  
  double get usagePercentage => totalBytes > 0 ? (usedBytes / totalBytes) * 100 : 0;
  
  String get usedSizeFormatted => _formatBytes(usedBytes);
  String get totalSizeFormatted => _formatBytes(totalBytes);
  String get freeSizeFormatted => _formatBytes(freeBytes);
  
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}