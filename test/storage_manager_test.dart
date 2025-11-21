import 'package:flutter_test/flutter_test.dart';
import 'package:fihirana/services/storage_manager.dart';

void main() {
  group('StorageManager Tests', () {
    late StorageManager storageManager;

    setUp(() {
      storageManager = StorageManager();
    });

    test('StorageManager singleton works correctly', () {
      final instance1 = StorageManager();
      final instance2 = StorageManager();
      expect(identical(instance1, instance2), true);
    });

    test('Format bytes works correctly', () {
      expect(storageManager.formatBytes(0), '0 B');
      expect(storageManager.formatBytes(1024), '1.0 KB');
      expect(storageManager.formatBytes(1024 * 1024), '1.0 MB');
      expect(storageManager.formatBytes(1024 * 1024 * 1024), '1.0 GB');
    });

    test('Initial state is correct', () {
      expect(storageManager.isInitialized, false);
    });
  });
}