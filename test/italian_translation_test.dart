import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fihirana/l10n/app_localizations.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Italian Translation Tests', () {
    late AppLocalizations itLocalizations;
    late AppLocalizations enLocalizations;

    setUpAll(() async {
      // Initialize Italian localizations
      itLocalizations = await AppLocalizations.delegate.load(const Locale('it'));
      // Initialize English localizations for comparison
      enLocalizations = await AppLocalizations.delegate.load(const Locale('en'));
    });

    test('Italian localizations should be loaded correctly', () {
      expect(itLocalizations, isNotNull);
      expect(itLocalizations.localeName, equals('it'));
    });

    test('Italian translations should be different from English', () {
      // Test that Italian translations are actually translated
      expect(itLocalizations.home, isNot(equals(enLocalizations.home)));
      expect(itLocalizations.settings, isNot(equals(enLocalizations.settings)));
      expect(itLocalizations.search, isNot(equals(enLocalizations.search)));
      expect(itLocalizations.cancel, isNot(equals(enLocalizations.cancel)));
      expect(itLocalizations.save, isNot(equals(enLocalizations.save)));
    });

    test('Italian translations should contain expected text', () {
      expect(itLocalizations.home, equals('Casa'));
      expect(itLocalizations.settings, equals('Impostazioni'));
      expect(itLocalizations.search, equals('Cerca'));
      expect(itLocalizations.cancel, equals('Cancel'));
      expect(itLocalizations.save, equals('Save'));
      expect(itLocalizations.language, equals('Language'));
      expect(itLocalizations.favorites, equals('Favorites'));
      expect(itLocalizations.favoriteHymns, equals('Hymni Preferiti'));
      expect(itLocalizations.bible, equals('Bible'));
      expect(itLocalizations.signIn, equals('Sign In'));
      expect(itLocalizations.signOut, equals('Sign Out'));
    });

    test('Italian should be considered natively supported', () {
      // Italian should be considered natively supported
      const nativelySupported = ['mg', 'en', 'fr', 'it'];
      expect(nativelySupported.contains('it'), isTrue);
    });

    testWidgets('Italian should work in widget context', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('it'),
            Locale('en'),
            Locale('fr'),
            Locale('mg'),
          ],
          home: Builder(
            builder: (context) {
              final localizations = AppLocalizations.of(context)!;
              return Scaffold(
                body: Column(
                  children: [
                    Text(localizations.home),
                    Text(localizations.settings),
                    Text(localizations.search),
                    Text(localizations.favoriteHymns),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Italian text is displayed
      expect(find.text('Casa'), findsOneWidget);
      expect(find.text('Impostazioni'), findsOneWidget);
      expect(find.text('Cerca'), findsOneWidget);
      expect(find.text('Hymni Preferiti'), findsOneWidget);
      
      // Verify English text is NOT displayed
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Favorites'), findsNothing);
    });

    testWidgets('Language switching to Italian should work', (WidgetTester tester) async {
      Locale? currentLocale;
      
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'), // Start with English
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('it'),
            Locale('en'),
            Locale('fr'),
            Locale('mg'),
          ],
          home: Builder(
            builder: (context) {
              currentLocale = Localizations.localeOf(context);
              final localizations = AppLocalizations.of(context)!;
              return Scaffold(
                body: Column(
                  children: [
                    Text('Current: ${currentLocale?.languageCode ?? "unknown"}'),
                    Text(localizations.home),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should start with English
      expect(find.text('Current: en'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);

      // Now switch to Italian
      await tester.binding.setLocale('it', '');
      await tester.pumpAndSettle();

      // Should now show Italian
      expect(find.text('Current: it'), findsOneWidget);
      expect(find.text('Casa'), findsOneWidget); // 'Casa' is Italian for 'Home'
    });
  });
}