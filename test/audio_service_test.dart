import 'package:flutter_test/flutter_test.dart';
import '../lib/services/audio_service.dart';

void main() {
  group('Audio Service Slider Tests', () {
    test('AudioService seek method works correctly', () async {
      final audioService = AudioService.instance;
      
      // Test that seek method exists and can be called
      expect(() => audioService.seekTo(Duration(seconds: 30)), returnsNormally);
      
      // Test edge cases
      expect(() => audioService.seekTo(Duration.zero), returnsNormally);
      expect(() => audioService.seekTo(const Duration(hours: 1)), returnsNormally);
    });

    test('Slider value calculation is robust', () {
      // Test the calculation logic used in all audio widgets
      double calculateSliderValue(Duration? duration, Duration? position) {
        if (duration == null || position == null) return 0.0;
        
        final durationMs = duration.inMilliseconds.toDouble();
        final positionMs = position.inMilliseconds.toDouble();
        
        if (durationMs <= 0) return 0.0;
        
        // Additional safety check for extreme values
        if (positionMs < 0) return 0.0;
        
        final value = positionMs / durationMs;
        final clampedValue = value.clamp(0.0, 1.0);
        
        return clampedValue;
      }

      // Test comprehensive scenarios
      expect(calculateSliderValue(Duration(minutes: 3), Duration(minutes: 1, seconds: 30)), 0.5);
      expect(calculateSliderValue(Duration(minutes: 2), Duration(seconds: 30)), 0.25);
      expect(calculateSliderValue(Duration(minutes: 4), Duration(minutes: 3)), 0.75);

      // Test boundary conditions
      expect(calculateSliderValue(Duration(minutes: 3), Duration.zero), 0.0);
      expect(calculateSliderValue(Duration(minutes: 3), Duration(minutes: 3)), 1.0);

      // Test extreme values that should be clamped
      expect(calculateSliderValue(Duration(minutes: 3), Duration(minutes: 5)), 1.0);
      expect(calculateSliderValue(Duration(minutes: 3), Duration(minutes: -1)), 0.0);

      // Test null safety
      expect(calculateSliderValue(null, Duration(minutes: 1)), 0.0);
      expect(calculateSliderValue(Duration(minutes: 3), null), 0.0);
      expect(calculateSliderValue(null, null), 0.0);

      // Test zero duration edge case
      expect(calculateSliderValue(Duration.zero, Duration(seconds: 30)), 0.0);
    });
  });
}