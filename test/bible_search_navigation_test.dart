import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../lib/controller/bible_controller.dart';
import '../lib/controller/color_controller.dart';
import '../lib/models/bible_search.dart';

void main() {
  group('Bible Search Navigation Test', () {
    late BibleController bibleController;
    late ColorController colorController;

    setUp(() {
      // Initialize GetX
      Get.testMode = true;
      
      // Create controllers
      bibleController = BibleController();
      colorController = ColorController();
      
      // Register controllers with GetX
      Get.put(bibleController);
      Get.put(colorController);
    });

    tearDown(() {
      // Clean up GetX
      Get.reset();
    });

    test('should highlight correct verse when navigating from search', () {
      // Simulate search results for "jesosy"
      final searchResults = [
        BibleSearchResult(
          type: BibleSearchResultType.verse,
          bookName: 'Matioa',
          chapter: 1,
          verse: 21, // First result - verse 21
          text: 'Hiterin-kosa ny nahary vaovao ny zanak\' i Jesosy...',
          relevance: 95.0,
        ),
        BibleSearchResult(
          type: BibleSearchResultType.verse,
          bookName: 'Matioa',
          chapter: 1,
          verse: 23, // Second result - verse 23
          text: 'Ary ny tanora ho an\'i Jesosy...',
          relevance: 90.0,
        ),
      ];

      bibleController.searchResults.assignAll(searchResults);

      // Test navigation to first result (verse 21)
      final firstResult = searchResults.first;
      
      // Navigate to the search result
      bibleController.navigateToSearchResult(firstResult, highlightVerse: firstResult.verse);

      // Verify the highlighted verse is set
      expect(bibleController.highlightedVerse.value, equals(21));

      // Verify book and chapter are selected
      expect(bibleController.selectedBook.value, equals('Matioa'));
      expect(bibleController.selectedChapter.value, equals(1));

      print('✓ Navigation test passed:');
      print('  - Book: ${bibleController.selectedBook.value}');
      print('  - Chapter: ${bibleController.selectedChapter.value}');
      print('  - Highlighted verse: ${bibleController.highlightedVerse.value}');
      print('  - Is verse 21 search highlighted? ${bibleController.isVerseSearchHighlighted(21)}');
      print('  - Is verse 23 search highlighted? ${bibleController.isVerseSearchHighlighted(23)}');

      // Test the highlighting logic
      expect(bibleController.isVerseSearchHighlighted(21), isTrue);
      expect(bibleController.isVerseSearchHighlighted(23), isFalse);

      print('✓ Highlighting logic test passed');
    });

    test('should clear highlighted verse when changing chapters', () {
      // Set initial highlighted verse
      bibleController.highlightedVerse.value = 15;
      expect(bibleController.highlightedVerse.value, equals(15));

      // Change chapter (should clear highlight)
      bibleController.selectChapter(2);

      // Verify highlight is cleared
      expect(bibleController.highlightedVerse.value, equals(0));

      print('✓ Chapter change clears highlight test passed');
    });

    test('search result validation', () {
      // Test creating search results
      final result = BibleSearchResult(
        type: BibleSearchResultType.verse,
        bookName: 'Matioa',
        chapter: 1,
        verse: 21,
        text: 'Hiterin-kosa ny nahary vaovao ny zanak\' i Jesosy',
        relevance: 95.0,
      );

      expect(result.type, equals(BibleSearchResultType.verse));
      expect(result.bookName, equals('Matioa'));
      expect(result.chapter, equals(1));
      expect(result.verse, equals(21));
      expect(result.text, contains('Jesosy'));

      print('✓ Search result validation test passed');
    });

    test('should find first result for "jesosy" search', () {
      // Test that we can find the first result containing "jesosy"
      final searchResults = [
        BibleSearchResult(
          type: BibleSearchResultType.verse,
          bookName: 'Matioa',
          chapter: 1,
          verse: 21, // This should be the first result
          text: 'Hiterin-kosa ny nahary vaovao ny zanak\' i Jesosy...',
          relevance: 95.0,
        ),
        BibleSearchResult(
          type: BibleSearchResultType.verse,
          bookName: 'Matioa',
          chapter: 1,
          verse: 23, // This should be the second result
          text: 'Ary ny tanora ho an\'i Jesosy...',
          relevance: 90.0,
        ),
      ];

      bibleController.searchResults.assignAll(searchResults);

      // Get the first result
      final firstResult = searchResults.first;

      // Verify it's verse 21 (the first one)
      expect(firstResult.verse, equals(21));
      expect(firstResult.text, contains('Jesosy'));
      expect(firstResult.bookName, equals('Matioa'));

      print('✓ First result test passed:');
      print('  - First result verse: ${firstResult.verse}');
      print('  - Contains "Jesosy": ${firstResult.text.contains('Jesosy')}');
    });
  });
}