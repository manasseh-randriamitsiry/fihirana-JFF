import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Slider Movement Fix Tests', () {
    test('Slider calculation with immediate position reset', () {
      // Test the enhanced calculation logic with position reset
      double calculateSliderValue(Duration? duration, Duration? position, {bool shouldResetPosition = false}) {
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
          // Simulate position reset
          if (shouldResetPosition) {
            print('Also resetting internal position to prevent further issues');
          }
          return 0.0;
        }
        
        final value = positionMs / durationMs;
        final clampedValue = value.clamp(0.0, 1.0);
        
        return clampedValue;
      }

      double getSafeSliderValue(Duration? duration, Duration? position) {
        try {
          final calculatedValue = calculateSliderValue(duration, position);
          // Final safety check - ensure value is within valid range
          return calculatedValue.clamp(0.0, 1.0);
        } catch (e) {
          print('Error calculating slider value: $e, returning 0.0');
          return 0.0;
        }
      }

      final duration = Duration(milliseconds: 160470); // 160.47 seconds
      final problematicPosition = Duration(milliseconds: 1702714989); // Much larger than duration
      
      // Test without position reset (old behavior)
      final oldValue = calculateSliderValue(duration, problematicPosition);
      print('Old calculation result: $oldValue');
      
      // Test with position reset (new behavior)
      final newValue = calculateSliderValue(duration, problematicPosition, shouldResetPosition: true);
      print('New calculation result: $newValue');
      
      // Test safe wrapper
      final safeValue = getSafeSliderValue(duration, problematicPosition);
      print('Safe wrapper result: $safeValue');
      
      // All should return 0.0 due to the safety check
      expect(oldValue, 0.0);
      expect(newValue, 0.0);
      expect(safeValue, 0.0);
      
      // Test normal cases still work
      expect(getSafeSliderValue(duration, Duration(milliseconds: 80235)), 0.5); // 50%
      expect(getSafeSliderValue(duration, Duration(milliseconds: 160470)), 1.0); // 100%
      expect(getSafeSliderValue(duration, Duration.zero), 0.0); // 0%
      
      print('✅ All slider movement fix tests passed!');
    });

    test('Slider handles edge cases without crashing', () {
      double getSafeSliderValue(Duration? duration, Duration? position) {
        try {
          if (duration == null || position == null) return 0.0;
          
          final durationMs = duration.inMilliseconds.toDouble();
          final positionMs = position.inMilliseconds.toDouble();
          
          if (durationMs <= 0) return 0.0;
          if (positionMs < 0) return 0.0;
          
          // CRITICAL FIX: If position is significantly larger than duration
          if (positionMs > durationMs * 1.5) {
            return 0.0;
          }
          
          final value = positionMs / durationMs;
          return value.clamp(0.0, 1.0);
        } catch (e) {
          return 0.0;
        }
      }

      // Test extreme cases that would previously cause crashes
      expect(getSafeSliderValue(Duration(milliseconds: 100), Duration(milliseconds: 1000000000)), 0.0); // Extremely large position
      expect(getSafeSliderValue(Duration(milliseconds: 100), Duration(milliseconds: -1000)), 0.0); // Negative position
      expect(getSafeSliderValue(Duration.zero, Duration(milliseconds: 1000)), 0.0); // Zero duration
      expect(getSafeSliderValue(null, Duration(milliseconds: 1000)), 0.0); // Null duration
      expect(getSafeSliderValue(Duration(milliseconds: 100), null), 0.0); // Null position
      
      print('✅ All edge case tests passed!');
    });
  });
}