import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fihirana/core/design_system/app_theme.dart';
import 'package:fihirana/features/audio/presentation/widgets/compact_audio_player_widget.dart';
import 'package:fihirana/features/audio/presentation/widgets/modern_audio_player_widget.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/l10n/app_localizations.dart';

void main() {
  final hymn = Hymn(
    id: 'h1',
    hymnNumber: '12',
    title: 'Ny fihirana lehibe',
    verses: ['Andalana voalohany.'],
    createdAt: DateTime(2026, 3, 4),
    createdBy: '',
  );

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFihiranaTheme(
          ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED)),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
    await tester.pump();
  }

  testWidgets('the full player fits the screen', (tester) async {
    await pump(tester, ModernAudioPlayerWidget(hymn: hymn));
    expect(tester.takeException(), isNull);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('the compact player fits its sheet', (tester) async {
    await pump(tester, CompactAudioPlayerWidget(hymn: hymn));
    expect(tester.takeException(), isNull);
    expect(find.byType(Slider), findsOneWidget);
  });
}
