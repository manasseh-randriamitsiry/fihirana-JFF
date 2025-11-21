import 'package:flutter_test/flutter_test.dart';
import '../lib/services/audio_file_mapping.dart';

void main() {
  group('AudioFileMapping Integration Tests', () {
    late AudioFileMapping audioMapping;

    setUp(() {
      audioMapping = AudioFileMapping();
    });

    test('should handle basic mapping operations', () {
      // Test basic functionality
      expect(audioMapping.hasAudio('1'), isFalse); // Initially false until mapping is loaded
      expect(audioMapping.getAudioFilename('1'), isNull);
      expect(audioMapping.getAudioUrl('1'), isNull);
      
      final stats = audioMapping.getStats();
      expect(stats['totalFiles'], equals(0));
      expect(stats['isExpired'], isTrue);
    });

    test('should handle empty mapping correctly', () {
      final audioFiles = audioMapping.getAllAudioFiles();
      expect(audioFiles, isEmpty);
      
      final availableIds = audioMapping.getAvailableHymnIds();
      expect(availableIds, isEmpty);
    });
  });
}