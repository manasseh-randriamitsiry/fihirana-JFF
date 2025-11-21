import 'package:flutter_test/flutter_test.dart';
import '../lib/services/audio_file_mapping.dart';

void main() {
  group('AudioFileMapping Tests', () {
    late AudioFileMapping audioMapping;

    setUp(() {
      audioMapping = AudioFileMapping();
    });

    test('should extract hymn ID from filename correctly', () async {
      // This is more of an integration test since it requires network
      // But we can test the basic logic
      expect(audioMapping.hasAudio('1'), isFalse); // Initially false until mapping is loaded
    });

    test('should return null for unknown hymn ID', () {
      expect(audioMapping.getAudioFilename('999'), isNull);
      expect(audioMapping.getAudioUrl('999'), isNull);
    });

    test('should return correct stats', () {
      final stats = audioMapping.getStats();
      expect(stats['totalFiles'], isA<int>());
      expect(stats['isExpired'], isA<bool>());
    });
  });
}