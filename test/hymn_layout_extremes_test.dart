import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fihirana/core/design_system/app_theme.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_detail_widgets.dart';
import 'package:fihirana/l10n/app_localizations.dart';

/// The page has to take a hymn of any shape. These are the extremes the
/// shipped corpus actually reaches — the longest title, seven verses, a 399
/// character verse and a 381 character chorus — rendered at the narrowest
/// phone and at double the system text size.
void main() {
  final String longVerse = List.filled(
    3,
    'Fitiavana tsy misy fetra no hita teo amin’ny hazo fijaliana, ary ny '
        'olona rehetra no antsoina hankasitraka izany amin’ny fonony.',
  ).join(' ');

  final String longChorus = List.filled(
    9,
    'Famindram-po tsy hay lany sy fahasoavana tsy mety ritra no entin’ny '
        'Tompo manolotra ny tenany ho antsika rehetra eto an-tany.',
  ).join(' ');

  Hymn extremes() => Hymn(
        id: '214',
        hymnNumber: '214',
        title: 'VOAFANTSIKA HO AHY TEO AMINNY HAZO FIJALIANA IZY',
        verses: [for (var i = 1; i <= 7; i++) 'Andalana $i. $longVerse'],
        bridge: longChorus,
        hymnHint:
            'Hira fiderana ampiasaina mandritra ny fotoam-pivavahana amin’ny '
            'alahady maraina, rehefa miara-mihira ny fiangonana manontolo.',
        createdAt: DateTime(2026, 1, 1),
        createdBy: 'Fiangonana JFF',
        createdByEmail: 'jff@example.com',
      );

  Future<void> pumpPage(
    WidgetTester tester, {
    required Size phone,
    required double textScale,
  }) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = phone * 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildFihiranaTheme(
          ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED)),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: HymnPageWidget(
            hymn: extremes(),
            fontSize: 21,
            countFontSize: 22,
            isUserAuthenticated: false,
            onNoteEdit: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in const [Size(320, 568), Size(430, 932)]) {
    for (final scale in const [1.0, 2.0]) {
      testWidgets(
        'the longest hymn reads without overflow at '
        '${size.width.toInt()}x${size.height.toInt()} and ${scale}x text',
        (tester) async {
          await pumpPage(tester, phone: size, textScale: scale);
          expect(find.textContaining('VOAFANTSIKA'), findsOneWidget);

          // The chorus is a pinned header, so scrolling past it exercises the
          // delegate's measured extent as well as the verse rows.
          for (var i = 0; i < 12; i++) {
            await tester.drag(
              find.byType(CustomScrollView),
              const Offset(0, -400),
              warnIfMissed: false,
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
          }

          final position =
              tester.state<ScrollableState>(find.byType(Scrollable)).position;
          expect(position.pixels, greaterThan(0));
        },
      );
    }
  }
}
