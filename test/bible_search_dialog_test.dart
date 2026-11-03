import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:fihirana/core/design_system/app_theme.dart';
import 'package:fihirana/features/bible/domain/entities/bible_search.dart';
import 'package:fihirana/features/bible/domain/usecases/get_all_books_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/get_book_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/search_books_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/search_verses_usecase.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_book_controller.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_search_controller.dart';
import 'package:fihirana/features/bible/presentation/widgets/bible_search_dialog.dart';
import 'package:fihirana/l10n/app_localizations.dart';

import 'fakes/fake_bible_service.dart';

/// What the dialog has to get right, seen as a person sees it: which scope is
/// lit, what an empty field says, and whether the rows on screen belong to the
/// word in the field.
void main() {
  late FakeBibleService service;
  late BibleBookController books;
  late BibleSearchController search;

  setUp(() {
    Get.reset();
    service = FakeBibleService();
    books = Get.put(BibleBookController(
      getAllBooksUseCase: GetAllBooksUseCase(service),
      getBookUseCase: GetBookUseCase(service),
    ));
    search = Get.put(BibleSearchController(
      searchBooksUseCase: SearchBooksUseCase(service),
      searchVersesUseCase: SearchVersesUseCase(service),
    ));
  });

  tearDown(Get.reset);

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      theme: buildFihiranaTheme(
        ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED)),
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const BibleSearchDialog(),
              ),
              child: const Text('open'),
            ),
          ),
        );
      }),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// The field searches on a pause, and a pending timer schedules no frame, so
  /// the clock has to be moved past it before the results can appear.
  Future<void> type(WidgetTester tester, String word) async {
    await tester.enterText(find.byType(TextField), word);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
  }

  List<String> referencesOnScreen(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .where((data) => RegExp(r'^\d+:\d+$').hasMatch(data))
      .toList()
    ..sort();

  testWidgets('an empty field asks for a word and offers no rows',
      (tester) async {
    await openDialog(tester);

    expect(find.text('Enter word to search'), findsOne);
    expect(find.textContaining("Bindaao"), findsNothing);
  });

  testWidgets('the chapter the reader sits on is the lit scope',
      (tester) async {
    books.selectBook('Salamo');
    books.selectChapter(3);
    await openDialog(tester);

    final chapterChip = find.widgetWithText(ChoiceChip, 'Search in chapter 3');
    expect(chapterChip, findsOne);
    expect(
      tester.widget<ChoiceChip>(chapterChip).selected,
      isTrue,
      reason: 'a scope nobody can see is the reason a search looks broken',
    );
  });

  testWidgets(
      'a word absent from the chapter finds nothing until the scope moves',
      (tester) async {
    books.selectBook('Josoa');
    books.selectChapter(1);
    await openDialog(tester);
    await type(tester, 'Bindaao');

    expect(find.text('No search results'), findsOne);
    expect(referencesOnScreen(tester), isEmpty);

    await tester.tap(find.text('Search entire Bible'));
    await tester.pumpAndSettle();

    expect(search.searchResults.map((r) => r.displayText),
        ['Salamo 1:1', 'Salamo 2:1']);
    expect(referencesOnScreen(tester), ['1:1', '2:1']);
  });

  testWidgets('no chapter open means the whole Bible, not a dead search',
      (tester) async {
    search.setSearchContext(BibleSearchContext.currentChapter);
    await openDialog(tester);
    await type(tester, 'Bindaao');

    expect(referencesOnScreen(tester), ['1:1', '2:1'],
        reason: 'the reader can search before a chapter is on screen');
    expect(
        find.byWidgetPredicate((w) =>
            w is ChoiceChip &&
            (w.label as Text).data!.startsWith('Search in chapter')),
        findsNothing);
  });

  testWidgets('the clear button empties the rows with the field',
      (tester) async {
    await openDialog(tester);
    await type(tester, 'Bindaao');
    expect(search.searchResults, hasLength(2));

    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();

    expect(search.searchResults, isEmpty);
    expect(referencesOnScreen(tester), isEmpty);
    expect(find.text('Enter word to search'), findsOne);
  });

  testWidgets(
      'a reopened dialog does not show the last search under a blank field',
      (tester) async {
    await openDialog(tester);
    await type(tester, 'Bindaao');
    expect(search.searchResults, hasLength(2));

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(search.searchQuery.value, isEmpty);
    expect(search.searchResults, isEmpty);
    expect(referencesOnScreen(tester), isEmpty);

    // And the same word still searches, rather than being taken as already done.
    final callsBefore = service.searchVersesCalls;
    await type(tester, 'Bindaao');
    expect(service.searchVersesCalls, greaterThan(callsBefore));
    expect(search.searchResults, hasLength(2));
  });

  testWidgets('the book scope lists books and opening one selects it',
      (tester) async {
    await openDialog(tester);
    await tester.tap(find.text('Search Books'));
    await tester.pumpAndSettle();

    await type(tester, 'Jos');
    expect(find.text('Josoa'), findsOne);
    expect(find.text('Books'), findsOne,
        reason:
            'a book row has no reference, and its kind is a translated word');
    expect(referencesOnScreen(tester), isEmpty);

    await tester.tap(find.text('Josoa'));
    await tester.pumpAndSettle();

    expect(find.byType(BibleSearchDialog), findsNothing);
    expect(books.selectedBook.value, 'Josoa');
  });

  testWidgets('the row shows the reference and marks the matched phrase',
      (tester) async {
    await openDialog(tester);
    await type(tester, 'Bindaao');

    // The reference sits in the figure column, the book under the words.
    expect(referencesOnScreen(tester), ['1:1', '2:1']);
    expect(find.text('Salamo'), findsNWidgets(2));

    final rich = tester.widgetList<RichText>(find.byType(RichText)).where((rt) {
      final root = rt.text;
      if (root is! TextSpan || root.children == null) return false;
      return root.children!.any((c) =>
          c is TextSpan &&
          c.text == 'Bindaao' &&
          c.style?.backgroundColor != null);
    });
    expect(rich, isNotEmpty,
        reason: 'a hit the eye cannot find on the page is not a highlight');
  });

  testWidgets('a hit late in a long verse still reaches the screen',
      (tester) async {
    await openDialog(tester);
    await type(tester, "herin'ny");

    final snippets = tester
        .widgetList<RichText>(find.byType(RichText))
        .map((r) => r.text.toPlainText())
        .where((text) => text.contains("herin'ny"))
        .toList();
    expect(snippets, hasLength(1));
    expect(snippets.single, startsWith('… '),
        reason: 'the row sets three lines, so the snippet opens at the hit');
  });
}
