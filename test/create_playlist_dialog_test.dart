import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/app_theme.dart';
import 'package:fihirana/features/playlist/presentation/widgets/create_playlist_dialog.dart';
import 'package:fihirana/l10n/app_localizations.dart';

void main() {
  Future<ThemeData> pumpDialog(
    WidgetTester tester,
    Brightness brightness, {
    required void Function(String title, DateTime date) onCreate,
  }) async {
    final theme = buildFihiranaTheme(
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF2F6FED),
        brightness: brightness,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                key: const Key('open-playlist-dialog'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => CreatePlaylistDialog(
                    title: 'New playlist',
                    hint: 'Playlist name',
                    onCreate: onCreate,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-playlist-dialog')));
    await tester.pumpAndSettle();
    return theme;
  }

  testWidgets('creates and cancels without legacy colour dependencies',
      (tester) async {
    String? createdTitle;
    await pumpDialog(
      tester,
      Brightness.light,
      onCreate: (title, _) => createdTitle = title,
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(createdTitle, isNull);
    expect(find.byType(CreatePlaylistDialog), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Fiderana');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(createdTitle, 'Fiderana');
    expect(find.byType(CreatePlaylistDialog), findsNothing);

    await tester.tap(find.byKey(const Key('open-playlist-dialog')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CreatePlaylistDialog), findsNothing);
    expect(createdTitle, 'Fiderana');
  });

  testWidgets('dialog and date picker inherit the dark app theme',
      (tester) async {
    final theme = await pumpDialog(
      tester,
      Brightness.dark,
      onCreate: (_, __) {},
    );
    final surfaces = AppSurfaces.from(theme.colorScheme);
    final dialogSurface = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(Dialog),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(dialogSurface.color, surfaces.paper);
    expect(
      tester
          .widget<InputDecorator>(find.byType(InputDecorator))
          .decoration
          .fillColor,
      surfaces.sheet,
    );

    await tester.tap(find.byIcon(Icons.calendar_today));
    await tester.pumpAndSettle();
    final pickerContext = tester.element(find.byType(DatePickerDialog));
    expect(Theme.of(pickerContext).brightness, Brightness.dark);
    expect(Theme.of(pickerContext).colorScheme, theme.colorScheme);
    expect(tester.takeException(), isNull);
  });
}
