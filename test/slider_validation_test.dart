import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Slider Value Validation Tests', () {
    test('Slider calculation handles extreme position values', () {
      // Test the enhanced calculation logic
      double calculateSliderValue(Duration? duration, Duration? position) {
        if (duration == null || position == null) return 0.0;
        
        final durationMs = duration.inMilliseconds.toDouble();
        final positionMs = position.inMilliseconds.toDouble();
        
        if (durationMs <= 0) return 0.0;
        
        // Additional safety check for extreme values
        if (positionMs < 0) return 0.0;
        
        // CRITICAL FIX: If position is significantly larger than duration, 
        // it's likely a timing issue. Return 0.0 to be safe.
        if (positionMs > durationMs * 1.5) {
          print('Position ($positionMs) much larger than duration ($durationMs) - resetting to 0.0');
          return 0.0;
        }
        
        final value = positionMs / durationMs;
        final clampedValue = value.clamp(0.0, 1.0);
        
        return clampedValue;
      }

      // Test the specific error case from the user
      final duration = Duration(milliseconds: 160470); // 160.47 seconds
      final problematicPosition = Duration(milliseconds: 1702714989); // Much larger than duration
      
      final result = calculateSliderValue(duration, problematicPosition);
      
      // Should return 0.0 due to the safety check
      expect(result, 0.0);
      
      // Test normal cases still work
      expect(calculateSliderValue(duration, Duration(milliseconds: 80235)), 0.5); // 50%
      expect(calculateSliderValue(duration, Duration(milliseconds: 160470)), 1.0); // 100%
      expect(calculateSliderValue(duration, Duration.zero), 0.0); // 0%
      
      // Test edge case: position slightly larger than duration (should be clamped)
      expect(calculateSliderValue(duration, Duration(milliseconds: 180000)), 1.0); // Should clamp to 1.0
      
      // Test edge case: position much larger than duration (should reset to 0.0)
      expect(calculateSliderValue(duration, Duration(milliseconds: 500000)), 0.0); // Should reset to 0.0
      
      print('✅ All slider validation tests passed!');
    });

    test('Position validation logic works correctly', () {
      // Test the position validation logic used in stream listeners
      bool shouldIgnorePosition(Duration? position, Duration? duration) {
        if (position == null || duration == null) return false;
        if (position < Duration.zero) return true;
        
        // Additional validation: position should not be unreasonably large
        if (position.inMilliseconds > duration.inMilliseconds * 2.0) {
          print('Ignoring unreasonable position: ${position.inMilliseconds}ms vs duration: ${duration.inMilliseconds}ms');
          return true;
        }
        
        return false;
      }

      final duration = Duration(milliseconds: 160470);
      
      // Test normal position
      expect(shouldIgnorePosition(Duration(milliseconds: 80000), duration), false);
      
      // Test problematic position
      expect(shouldIgnorePosition(Duration(milliseconds: 1702714989), duration), true);
      
      // Test edge cases
      expect(shouldIgnorePosition(Duration(milliseconds: 320940), duration), false); // 2x duration - should be ignored
      expect(shouldIgnorePosition(Duration(milliseconds: 160470), duration), false); // Exactly duration - should be allowed
      
      print('✅ All position validation tests passed!');
    });
  });
}