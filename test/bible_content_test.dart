import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../lib/controller/bible_controller.dart';
import '../lib/controller/color_controller.dart';
import '../lib/services/bible_service.dart';

void main() {
  group('Bible Content Verification', () {
    late BibleService bibleService;
    late BibleController bibleController;
    late ColorController colorController;

    setUp(() {
      Get.testMode = true;
      bibleService = BibleService();
      bibleController = BibleController();
      colorController = ColorController();
      Get.put(bibleController);
      Get.put(colorController);
    });

    tearDown(() {
      Get.reset();
    });

    test('should find "Jesosy" in Jaona book', () async {
      // Initialize the Bible service
      await bibleService.initialize((message) => print('Loading: $message'));

      // Get the Jaona book
      final jaonaBook = bibleService.getBookSync('Jaona');

      if (jaonaBook == null) {
        print('❌ Jaona book not found');
        return;
      }

      // Get chapter 11
      final chapter11 = jaonaBook.getChapter(11);

      if (chapter11 == null) {
        print('❌ Chapter 11 not found in Jaona');
        return;
      }

      print('✅ Found Jaona chapter 11 with ${chapter11!.verses.length} verses');

      // Search for "Jesosy" in chapter 11
      final jesosyVerses = <int, String>{};
      
      chapter11!.verses.forEach((verseNum, verseText) {
        if (verseText.toLowerCase().contains('jesosy')) {
          jesosyVerses[verseNum] = verseText;
          print('Found "Jesosy" in verse $verseNum: "$verseText"');
        }
      });

      print('\n📝 All verses containing "Jesosy" in Jaona 11:');
      jesosyVerses.forEach((verseNum, text) {
        print('  Verse $verseNum: "$text"');
      });

      // Check specifically for verse 35
      if (jesosyVerses.containsKey(35)) {
        final verse35Text = jesosyVerses[35]!;
        print('\n🎯 Verse 35 found: "$verse35Text"');
        
        // Check if it contains "nitomany"
        if (verse35Text.toLowerCase().contains('nitomany')) {
          print('✅ Verse 35 contains "nitomany"');
        } else {
          print('❌ Verse 35 does NOT contain "nitomany"');
        }
      } else {
        print('\n❌ Verse 35 NOT found in search results');
      }

      expect(jesosyVerses.isNotEmpty, isTrue);
    });

    test('should search for "Jesosy" across all books', () async {
      // Initialize the Bible service
      await bibleService.initialize((message) => print('Loading: $message'));

      // Search for "Jesosy"
      bibleController.performSearch('Jesosy');

      // Wait for search to complete
      await Future.delayed(const Duration(milliseconds: 1000));

      final searchResults = bibleController.searchResults;

      print('\n🔍 Search results for "Jesosy":');
      for (final result in searchResults.take(10)) {
        print('  ${result.bookName} ${result.chapter}:${result.verse} - "${result.text}"');
      }

      // Look for the expected result
      final expectedResult = searchResults.where((result) =>
        result.bookName == 'Jaona' && 
        result.chapter == 11 && 
        result.verse == 35
      ).firstOrNull;

      if (expectedResult != null) {
        print('\n✅ Expected result found: Jaona 11:35');
        print('   Text: "${expectedResult!.text}"');
      } else {
        print('\n❌ Expected result NOT found');
        print('\n📋 All Jaona results:');
        final jaonaResults = searchResults.where((result) => result.bookName == 'Jaona');
        for (final result in jaonaResults) {
          print('  ${result.chapter}:${result.verse} - "${result.text}"');
        }
      }

      expect(searchResults.isNotEmpty, isTrue);
    });
  });
}