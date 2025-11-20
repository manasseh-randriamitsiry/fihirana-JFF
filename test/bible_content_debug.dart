import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../lib/controller/bible_controller.dart';
import '../lib/controller/color_controller.dart';
import '../lib/services/bible_service.dart';

void main() {
  group('Bible Content Debug', () {
    late BibleService bibleService;
    late BibleController bibleController;
    late ColorController colorController;

    setUp(() async {
      Get.testMode = true;
      bibleService = BibleService();
      bibleController = BibleController();
      colorController = ColorController();
      Get.put(bibleController);
      Get.put(colorController);
      
      // Initialize Bible service
      await bibleService.initialize((message) => print('Loading: $message'));
    });

    tearDown(() {
      Get.reset();
    });

    test('debug Jaona book content', () async {
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

      print('\n📖 Jaona Chapter 11 has ${chapter11!.verses.length} verses');

      // Print first few verses to see actual content
      chapter11!.verses.forEach((verseNum, verseText) {
        if (verseNum <= 40) { // Only print first 40 verses
          print('Verse $verseNum: "$verseText"');
        }
      });

      // Check specifically for verses around 35
      for (int i = 30; i <= 40; i++) {
        if (chapter11!.verses.containsKey(i)) {
          final verseText = chapter11!.verses[i]!;
          print('Verse $i: "$verseText"');
          print('  Contains "Jesosy": ${verseText.toLowerCase().contains('jesosy')}');
          print('  Contains "nitomany": ${verseText.toLowerCase().contains('nitomany')}');
          print('  Contains "tonga": ${verseText.toLowerCase().contains('tonga')}');
        }
      }
    });
  });
}