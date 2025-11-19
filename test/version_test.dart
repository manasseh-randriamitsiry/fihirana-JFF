import 'package:flutter_test/flutter_test.dart';
import '../lib/services/pubspec_service.dart';

void main() {
  group('Version Tests', () {
    test('PubspecService returns correct version', () async {
      final version = await PubspecService.getAppVersion();
      print('Current version: $version');
      expect(version, isNotNull);
      expect(version, equals('1.0.9'));
    });
  });
}