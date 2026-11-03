// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:fihirana/features/bible/data/services/bible_service.dart';

import 'fakes/fake_bible_service.dart';
import 'package:fihirana/features/bible/domain/usecases/get_all_books_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/get_book_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/search_books_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/search_verses_usecase.dart';
import 'package:fihirana/features/bible/domain/entities/bible_search.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_book_controller.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_search_controller.dart';

void main() {
  late FakeBibleService service;
  late BibleSearchController search;
  late BibleBookController books;

  setUp(() {
    Get.reset();
    service = FakeBibleService();
    books = Get.put(BibleBookController(
      getAllBooksUseCase: GetAllBooksUseCase(service),
      getBookUseCase: GetBookUseCase(service),
    ));
    search = BibleSearchController(
      searchBooksUseCase: SearchBooksUseCase(service),
      searchVersesUseCase: SearchVersesUseCase(service),
    );
  });

  tearDown(Get.reset);

  group('whole Bible scope', () {
    test('finds the word in every book and chapter', () async {
      search.setSearchContext(BibleSearchContext.allBible);
      search.updateSearchQuery('Bindaao');
      await search.performSearch();

      expect(search.searchResults.map((r) => r.displayText),
          containsAll(['Salamo 1:1', 'Salamo 2:1']));
    });

    test('matching is case insensitive', () async {
      search.setSearchContext(BibleSearchContext.allBible);
      search.updateSearchQuery('tOMpo maaLMA');
      await search.performSearch();

      expect(search.searchResults, hasLength(3));
    });

    test('a query with no hit reports nothing instead of everything', () async {
      search.setSearchContext(BibleSearchContext.allBible);
      search.updateSearchQuery('zaiterany');
      await search.performSearch();

      expect(search.searchResults, isEmpty);
    });
  });

  group('current chapter scope', () {
    Future<List<String>> referencesInChapter() async {
      search.setSearchContext(BibleSearchContext.currentChapter);
      search.updateSearchQuery('Tompo maalma');
      await search.performSearch();
      return search.searchResults.map((r) => r.displayText).toList();
    }

    test('stays inside the chapter the reader is on', () async {
      books.selectBook('Salamo');
      books.selectChapter(1);
      expect(await referencesInChapter(), ['Salamo 1:2']);

      books.selectChapter(2);
      expect(await referencesInChapter(), ['Salamo 2:3']);
    });

    test('finds nothing when the chapter has no hit', () async {
      books.selectBook('Josoa');
      books.selectChapter(1);
      search.setSearchContext(BibleSearchContext.currentChapter);
      search.updateSearchQuery('Bindaao');
      await search.performSearch();

      expect(search.searchResults, isEmpty,
          reason: 'the word is in Psalms, not in the open chapter');
    });
  });

  group('books scope', () {
    test('returns books and can open one', () async {
      search.setSearchContext(BibleSearchContext.books);
      search.updateSearchQuery('Jos');
      await search.performSearch();

      expect(search.searchResults.map((r) => r.bookName), ['Josoa']);
      expect(search.searchResults.first.type, BibleSearchResultType.book);

      search.navigateToSearchResult(search.searchResults.first);
      expect(books.selectedBook.value, 'Josoa');
    });
  });

  group('scope survives the states the UI walks through', () {
    test('clearing the query and searching again still finds verses', () async {
      search.setSearchContext(BibleSearchContext.allBible);
      search.updateSearchQuery('Bindaao');
      await search.performSearch();
      expect(search.searchResults, hasLength(2));

      // The dialog's clear button empties the field, which runs this path.
      search.updateSearchQuery('');
      expect(search.searchResults, isEmpty);

      search.updateSearchQuery('Bindaao');
      await search.performSearch();
      expect(search.searchResults, hasLength(2),
          reason: 'a cleared search must not leave the scope unset');
    });

    test('a reset forgets the previous query so it can be searched again',
        () async {
      search.setSearchContext(BibleSearchContext.allBible);
      search.updateSearchQuery('Bindaao');
      await search.performSearch();
      expect(service.searchVersesCalls, 1);

      search.resetSearch();
      expect(search.searchQuery.value, isEmpty);
      expect(search.searchResults, isEmpty);

      // Reopening the dialog and typing the same word must re-run the search,
      // not be swallowed by the "already searched this" guard.
      search.updateSearchQuery('Bindaao');
      await search.performSearch();
      expect(service.searchVersesCalls, 2);
      expect(search.searchResults, hasLength(2));
    });

    test('a reset keeps the scope the user picked', () async {
      search.setSearchContext(BibleSearchContext.books);
      search.resetSearch();

      search.updateSearchQuery('Jos');
      await search.performSearch();
      expect(search.searchResults.map((r) => r.type),
          [BibleSearchResultType.book]);
    });

    test('a whitespace query searches nothing', () async {
      search.setSearchContext(BibleSearchContext.allBible);
      search.updateSearchQuery('   ');
      await search.performSearch();

      expect(service.searchVersesCalls, isZero);
      expect(search.searchResults, isEmpty);
    });
  });

  group('reader highlight', () {
    test('marks only the verses the search found in the open chapter',
        () async {
      books.selectBook('Salamo');
      books.selectChapter(1);
      search.setSearchContext(BibleSearchContext.allBible);
      search.updateSearchQuery('Bindaao');
      await search.performSearch();

      expect(search.isVerseSearchHighlighted(1), isTrue);
      expect(search.isVerseSearchHighlighted(2), isFalse);

      books.selectChapter(2);
      expect(search.isVerseSearchHighlighted(1), isTrue,
          reason: 'the same word opens the next chapter on its own hit');
      expect(search.isVerseSearchHighlighted(3), isFalse);

      books.selectBook('Josoa');
      books.selectChapter(1);
      expect(search.isVerseSearchHighlighted(1), isFalse);
    });

    test('marks nothing once the search is cleared', () async {
      books.selectBook('Salamo');
      books.selectChapter(1);
      search.setSearchContext(BibleSearchContext.allBible);
      search.updateSearchQuery('Bindaao');
      await search.performSearch();
      search.resetSearch();

      expect(search.isVerseSearchHighlighted(1), isFalse);
    });
  });

  test('the shipped corpus is searched in one pass, fast enough to type into',
      () async {
    final bibleService = BibleService();
    await bibleService.initialize();

    final stopwatch = Stopwatch()..start();
    final results = bibleService.searchVerses('Josoa');
    stopwatch.stop();

    print('searchVerses("Josoa") -> ${results.length} hits in '
        '${stopwatch.elapsedMilliseconds} ms');
    expect(results, isNotEmpty);
    expect(stopwatch.elapsedMilliseconds, lessThan(1500),
        reason: 'search runs on keystrokes; a multi-second scan blocks frames');
  });

  test('a chapter change re-runs a chapter search instead of reusing hits',
      () async {
    books.selectBook('Salamo');
    books.selectChapter(1);
    search.setSearchContext(BibleSearchContext.currentChapter);
    search.updateSearchQuery('Tompo maalma');
    await search.performSearch();
    expect(search.searchResults.map((r) => r.displayText), ['Salamo 1:2']);

    // The reader turns the page with the same word still in the field.
    books.selectChapter(2);
    await search.performSearch();
    expect(search.searchResults.map((r) => r.displayText), ['Salamo 2:3'],
        reason: 'the old guard compared only the word and the scope');
  });

  test('the shipped corpus repeats verse text but never a reference', () async {
    final bibleService = BibleService();
    await bibleService.initialize();

    final verses = bibleService.searchVerses('ny');
    final texts = verses.map((result) => result.text).toSet();
    final references = verses
        .map((result) => '${result.bookName} ${result.chapter}:${result.verse}')
        .toSet();

    expect(verses.length, greaterThan(texts.length),
        reason:
            'identical verse texts exist, so a row cannot be keyed by its text');
    expect(references, hasLength(verses.length),
        reason: 'the book/chapter/verse reference is what makes a row unique');
  });
}
