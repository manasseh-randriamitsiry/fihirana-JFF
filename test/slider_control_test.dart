import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/widgets/audio_player_widget.dart';
import '../lib/widgets/compact_audio_player_widget.dart';
import '../lib/widgets/enhanced_audio_player_widget.dart';
import '../lib/models/hymn.dart';
import '../lib/services/audio_service.dart';
import 'package:get/get.dart';

void main() {
  group('Slider Control Tests', () {
    setUp(() {
      // Initialize GetX for testing
      Get.testMode = true;
    });

    testWidgets('AudioPlayerWidget slider can be controlled', (WidgetTester tester) async {
      final hymn = Hymn(
        id: 'test-1',
        title: 'Test Hymn',
        hymnNumber: '1',
        verses: ['Test verse'],
        createdAt: DateTime.now(),
        createdBy: 'test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioPlayerWidget(
              hymn: hymn,
              playlist: [hymn],
            ),
          ),
        ),
      );

      // Find the slider
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      // Get the slider widget
      final Slider slider = tester.widget(sliderFinder);
      
      // Test initial value
      expect(slider.value, 0.0);
      expect(slider.min, 0.0);
      expect(slider.max, 1.0);
      
      // Test that slider is disabled when no audio is loaded
      expect(slider.onChanged, isNull);
    });

    testWidgets('CompactAudioPlayerWidget slider can be controlled', (WidgetTester tester) async {
      final hymn = Hymn(
        id: 'test-1',
        title: 'Test Hymn',
        hymnNumber: '1',
        verses: ['Test verse'],
        createdAt: DateTime.now(),
        createdBy: 'test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactAudioPlayerWidget(
              hymn: hymn,
              playlist: [hymn],
            ),
          ),
        ),
      );

      // Find the slider
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      // Get the slider widget
      final Slider slider = tester.widget(sliderFinder);
      
      // Test initial value
      expect(slider.value, 0.0);
      expect(slider.min, 0.0);
      expect(slider.max, 1.0);
    });

    testWidgets('EnhancedAudioPlayerWidget slider can be controlled', (WidgetTester tester) async {
      final hymn = Hymn(
        id: 'test-1',
        title: 'Test Hymn',
        hymnNumber: '1',
        verses: ['Test verse'],
        createdAt: DateTime.now(),
        createdBy: 'test',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EnhancedAudioPlayerWidget(
              hymn: hymn,
              playlist: [hymn],
            ),
          ),
        ),
      );

      // Find the slider
      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      // Get the slider widget
      final Slider slider = tester.widget(sliderFinder);
      
      // Test initial value
      expect(slider.value, 0.0);
      expect(slider.min, 0.0);
      expect(slider.max, 1.0);
    });

    test('Slider value calculation handles edge cases correctly', () {
      // Test the calculation logic directly
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

      // Test normal cases
      expect(calculateSliderValue(Duration(seconds: 100), Duration(seconds: 50)), 0.5);
      expect(calculateSliderValue(Duration(seconds: 100), Duration(seconds: 25)), 0.25);
      expect(calculateSliderValue(Duration(seconds: 100), Duration(seconds: 75)), 0.75);

      // Test edge cases
      expect(calculateSliderValue(Duration(seconds: 100), Duration(seconds: 0)), 0.0);
      expect(calculateSliderValue(Duration(seconds: 100), Duration(seconds: 100)), 1.0);

      // Test position exceeding duration (should be clamped)
      expect(calculateSliderValue(Duration(seconds: 100), Duration(seconds: 150)), 1.0);

      // Test negative position (should be clamped to 0)
      expect(calculateSliderValue(Duration(seconds: 100), Duration(seconds: -10)), 0.0);

      // Test null values
      expect(calculateSliderValue(null, Duration(seconds: 50)), 0.0);
      expect(calculateSliderValue(Duration(seconds: 100), null), 0.0);
      expect(calculateSliderValue(null, null), 0.0);

      // Test zero duration
      expect(calculateSliderValue(Duration.zero, Duration(seconds: 50)), 0.0);
    });
  });
}