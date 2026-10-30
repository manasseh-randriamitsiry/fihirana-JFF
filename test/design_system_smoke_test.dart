import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fihirana/core/design_system/app_theme.dart';
import 'package:fihirana/core/design_system/components/app_register_row.dart';
import 'package:fihirana/core/design_system/components/app_sheet.dart';
import 'package:fihirana/core/design_system/components/app_state_view.dart';
import 'package:fihirana/l10n/app_localizations.dart';

/// The register widgets are laid out inside vertical lists, where each item's
/// height is unbounded. That is the one place a stretched cross axis turns into
/// a null sliver geometry, so it is the thing this test holds.
void main() {
  ThemeData theme(Brightness brightness) => buildFihiranaTheme(
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F6FED),
          brightness: brightness,
        ),
      );

  Future<void> pumpRegister(WidgetTester tester, Brightness brightness) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme(brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView.separated(
            itemCount: 12,
            separatorBuilder: (_, __) => const AppRule(),
            itemBuilder: (context, index) => AppRegisterRow(
              figure: '${index + 1}',
              title: 'Hymn ${index + 1}',
              subtitle: index.isEven ? 'First line of the verse' : null,
              selected: index == 3,
              onTap: () {},
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ),
        ),
      ),
    );
  }

  for (final brightness in Brightness.values) {
    testWidgets('$brightness register lays out inside a list',
        (WidgetTester tester) async {
      await pumpRegister(tester, brightness);
      expect(tester.takeException(), isNull);
      expect(find.text('Hymn 1'), findsOneWidget);
      expect(find.byType(AppRule), findsWidgets);
    });

    testWidgets('$brightness states lay out inside a list',
        (WidgetTester tester) async {
      for (final state in AppState.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme(brightness),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AppStateView(
                state: state,
                emptyTitle: 'Nothing here yet',
                emptyMessage: 'The hymns you save appear here.',
                errorMessage: 'The connection failed.',
                onRetry: () {},
                child: const AppRegisterRow(figure: '1', title: 'Hymn 1'),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull, reason: '$state');
      }
    });
  }
}
