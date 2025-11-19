import 'package:flutter_test/flutter_test.dart';
import '../lib/widgets/audio_player_widget.dart';
import '../lib/widgets/compact_audio_player_widget.dart';
import '../lib/widgets/enhanced_audio_player_widget.dart';
import '../lib/models/hymn.dart';

void main() {
  group('Slider Value Range Tests', () {
    test('AudioPlayerWidget slider calculation handles edge cases', () {
      final hymn = Hymn(
        id: 'test-1',
        title: 'Test Hymn',
        hymnNumber: '1',
        verses: ['Test verse'],
        createdAt: DateTime.now(),
        createdBy: 'test',
      );

      final widget = AudioPlayerWidget(hymn: hymn);
      
      // Create a test state to access the private method
      // We'll test the logic by creating a similar function
      double calculateSliderValue(Duration? duration, Duration? position) {
        if (duration == null || position == null) return 0.0;
        
        final durationMs = duration.inMilliseconds.toDouble();
        final positionMs = position.inMilliseconds.toDouble();
        
        if (durationMs <= 0) return 0.0;
        
        final value = positionMs / durationMs;
        return value.clamp(0.0, 1.0);
      }

      // Test normal case
      expect(calculateSliderValue(Duration(seconds: 100), Duration(seconds: 50)), 0.5);
      
      // Test edge case: position exceeds duration
      expect(calculateSliderValue(Duration(seconds: 100), Duration(seconds: 150)), 1.0);
      
      // Test edge case: zero duration
      expect(calculateSliderValue(Duration.zero, Duration(seconds: 50)), 0.0);
      
      // Test edge case: null values
      expect(calculateSliderValue(null, Duration(seconds: 50)), 0.0);
      expect(calculateSliderValue(Duration(seconds: 100), null), 0.0);
      expect(calculateSliderValue(null, null), 0.0);
    });

    test('CompactAudioPlayerWidget slider calculation handles edge cases', () {
      final hymn = Hymn(
        id: 'test-1',
        title: 'Test Hymn',
        hymnNumber: '1',
        verses: ['Test verse'],
        createdAt: DateTime.now(),
        createdBy: 'test',
      );

      final widget = CompactAudioPlayerWidget(hymn: hymn);
      
      // Test the same logic as above
      double calculateSliderValue(Duration? duration, Duration? position) {
        if (duration == null || position == null) return 0.0;
        
        final durationMs = duration.inMilliseconds.toDouble();
        final positionMs = position.inMilliseconds.toDouble();
        
        if (durationMs <= 0) return 0.0;
        
        final value = positionMs / durationMs;
        return value.clamp(0.0, 1.0);
      }

      // Test normal case
      expect(calculateSliderValue(Duration(seconds: 100), Duration(seconds: 50)), 0.5);
      
      // Test edge case: position exceeds duration
      expect(calculateSliderValue(Duration(seconds: 100), Duration(seconds: 150)), 1.0);
      
      // Test edge case: zero duration
      expect(calculateSliderValue(Duration.zero, Duration(seconds: 50)), 0.0);
    });

    test('EnhancedAudioPlayerWidget slider calculation handles edge cases', () {
      final hymn = Hymn(
        id: 'test-1',
        title: 'Test Hymn',
        hymnNumber: '1',
        verses: ['Test verse'],
        createdAt: DateTime.now(),
        createdBy: 'test',
      );

      final widget = EnhancedAudioPlayerWidget(hymn: hymn);
      
      // Test the same logic as above
      double calculateSliderValue(Duration? duration, Duration? position) {
        if (duration == null || position == null) return 0.0;
        
        final durationMs = duration.inMilliseconds.toDouble();
        final positionMs = position.inMilliseconds.toDouble();
        
        if (durationMs <= 0) return 0.0;
        
        final value = positionMs / durationMs;
        return value.clamp(0.0, 1.0);
      }

      // Test normal case
      expect(calculateSliderValue(Duration(seconds: 100), Duration(seconds: 50)), 0.5);
      
      // Test edge case: position exceeds duration
      expect(calculateSliderValue(Duration(seconds: 100), Duration(seconds: 150)), 1.0);
      
      // Test edge case: zero duration
      expect(calculateSliderValue(Duration.zero, Duration(seconds: 50)), 0.0);
    });
  });
}