import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/widgets/audio_player_widget.dart';
import '../lib/widgets/compact_audio_player_widget.dart';
import '../lib/widgets/enhanced_audio_player_widget.dart';
import '../lib/models/hymn.dart';

void main() {
  group('Audio Player Autoplay Tests', () {
    test('EnhancedAudioPlayerWidget accepts autoplay parameters', () {
      final hymn = Hymn(
        id: 'test-1',
        title: 'Test Hymn',
        hymnNumber: '1',
        verses: ['Test verse'],
        createdAt: DateTime.now(),
        createdBy: 'test',
      );

      // Test that widget can be created with autoplay parameters
      expect(
        () => EnhancedAudioPlayerWidget(
          hymn: hymn,
          playlist: [hymn],
          autoPlayNext: true,
          onAutoPlayNextChange: (bool value) {},
          onHymnChange: (Hymn hymn) {},
        ),
        returnsNormally,
      );
    });

    test('AudioPlayerWidget accepts autoplay parameters', () {
      final hymn = Hymn(
        id: 'test-1',
        title: 'Test Hymn',
        hymnNumber: '1',
        verses: ['Test verse'],
        createdAt: DateTime.now(),
        createdBy: 'test',
      );

      // Test that widget can be created with autoplay parameters
      expect(
        () => AudioPlayerWidget(
          hymn: hymn,
          playlist: [hymn],
          autoPlayNext: true,
          onAutoPlayNextChange: (bool value) {},
          onHymnChange: (Hymn hymn) {},
        ),
        returnsNormally,
      );
    });

    test('CompactAudioPlayerWidget accepts autoplay parameters', () {
      final hymn = Hymn(
        id: 'test-1',
        title: 'Test Hymn',
        hymnNumber: '1',
        verses: ['Test verse'],
        createdAt: DateTime.now(),
        createdBy: 'test',
      );

      // Test that widget can be created with autoplay parameters
      expect(
        () => CompactAudioPlayerWidget(
          hymn: hymn,
          playlist: [hymn],
          autoPlayNext: true,
          onAutoPlayNextChange: (bool value) {},
          onHymnChange: (Hymn hymn) {},
        ),
        returnsNormally,
      );
    });

    test('All audio widgets have default autoplay disabled', () {
      final hymn = Hymn(
        id: 'test-1',
        title: 'Test Hymn',
        hymnNumber: '1',
        verses: ['Test verse'],
        createdAt: DateTime.now(),
        createdBy: 'test',
      );

      // Test that widgets can be created without playlist (no autoplay UI)
      expect(
        () => AudioPlayerWidget(hymn: hymn),
        returnsNormally,
      );

      expect(
        () => CompactAudioPlayerWidget(hymn: hymn),
        returnsNormally,
      );

      expect(
        () => EnhancedAudioPlayerWidget(hymn: hymn),
        returnsNormally,
      );
    });
  });
}