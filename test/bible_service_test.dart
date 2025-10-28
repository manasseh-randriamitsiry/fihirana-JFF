import 'package:flutter_test/flutter_test.dart';
import 'package:fihirana/services/bible_service.dart';
import 'package:fihirana/models/bible.dart';

void main() {
  group('BibleService Tests', () {
    late BibleService bibleService;

    setUp(() {
      bibleService = BibleService();
    });

    test('BibleService should be a singleton', () {
      final service1 = BibleService();
      final service2 = BibleService();
      expect(service1, same(service2));
    });

    test('BibleBook.fromJson should create a book with correct data', () {
      final jsonData = {
        '1': {
          '1': 'Verse 1 text',
          '2': 'Verse 2 text',
        },
        '2': {
          '1': 'Chapter 2 Verse 1 text',
        }
      };

      final book = BibleBook.fromJson(jsonData, 'Test Book');
      
      expect(book.name, 'Test Book');
      expect(book.chapters, 2);
      expect(book.chapterData.length, 2);
      
      final chapter1 = book.getChapter(1);
      expect(chapter1, isNotNull);
      expect(chapter1!.number, 1);
      expect(chapter1.verses.length, 2);
      expect(chapter1.getVerse(1), 'Verse 1 text');
      expect(chapter1.getVerse(2), 'Verse 2 text');
      
      final chapter2 = book.getChapter(2);
      expect(chapter2, isNotNull);
      expect(chapter2!.number, 2);
      expect(chapter2.verses.length, 1);
      expect(chapter2.getVerse(1), 'Chapter 2 Verse 1 text');
    });

    test('BibleChapter should return correct verses', () {
      final jsonData = {
        '1': 'First verse',
        '2': 'Second verse',
        '3': 'Third verse',
      };

      final chapter = BibleChapter.fromJson(jsonData, 1);
      
      expect(chapter.number, 1);
      expect(chapter.verses.length, 3);
      expect(chapter.getVerse(1), 'First verse');
      expect(chapter.getVerse(2), 'Second verse');
      expect(chapter.getVerse(3), 'Third verse');
      expect(chapter.getVerse(4), isNull);
    });

    test('BibleChapter should return verses in range', () {
      final jsonData = {
        '1': 'First verse',
        '2': 'Second verse',
        '3': 'Third verse',
        '4': 'Fourth verse',
        '5': 'Fifth verse',
      };

      final chapter = BibleChapter.fromJson(jsonData, 1);
      final verses = chapter.getVersesInRange(2, 4);
      
      expect(verses.length, 3);
      expect(verses[0], 'Second verse');
      expect(verses[1], 'Third verse');
      expect(verses[2], 'Fourth verse');
    });
  });
}