import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/models/daily_verse.dart';
import 'package:fihirana/services/features/bible_service.dart';
import 'package:fihirana/data/inspiring_verses.dart';
import 'package:fihirana/utility/bible_book_order.dart';
import 'package:fihirana/widgets/common/daily_verse_notification.dart';

class DailyVerseService {
  static final DailyVerseService _instance = DailyVerseService._internal();
  factory DailyVerseService() => _instance;
  DailyVerseService._internal();

  final BibleService _bibleService = BibleService();
  static const String _lastVerseKey = 'last_daily_verse';
  static const String _lastVerseDateKey = 'last_daily_verse_date';

  /// Get the verse of the day
  Future<DailyVerse> getVerseOfTheDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    // Check if we already have a verse for today
    final lastVerseDate = prefs.getString(_lastVerseDateKey);
    if (lastVerseDate == todayString) {
      // Try to get cached verse data
      final book = prefs.getString('${_lastVerseKey}_book');
      final chapter = prefs.getInt('${_lastVerseKey}_chapter');
      final verse = prefs.getInt('${_lastVerseKey}_verse');
      final text = prefs.getString('${_lastVerseKey}_text');
      final reference = prefs.getString('${_lastVerseKey}_reference');

      if (book != null &&
          chapter != null &&
          verse != null &&
          text != null &&
          reference != null) {
        return DailyVerse(
          book: book,
          chapter: chapter,
          verse: verse,
          text: text,
          reference: reference,
          date: DateTime.parse(todayString),
        );
      }
    }

    // Generate new verse for today
    final newVerse = await _generateRandomVerse();

    // Save it with individual keys
    await prefs.setString(_lastVerseDateKey, todayString);
    await prefs.setString('${_lastVerseKey}_book', newVerse.book);
    await prefs.setInt('${_lastVerseKey}_chapter', newVerse.chapter);
    await prefs.setInt('${_lastVerseKey}_verse', newVerse.verse);
    await prefs.setString('${_lastVerseKey}_text', newVerse.text);
    await prefs.setString('${_lastVerseKey}_reference', newVerse.reference);

    return newVerse;
  }

  /// Generate a random verse from the curated list of inspiring verses
  Future<DailyVerse> _generateRandomVerse() async {
    await _bibleService.initialize((message) {
      if (kDebugMode) {
        print('Bible service: $message');
      }
    });

    // Try to get a verse from the curated list
    try {
      final random = Random();
      // Try up to 10 times to find a valid verse from the list
      for (int i = 0; i < 10; i++) {
        final verseData =
            InspiringVerses.list[random.nextInt(InspiringVerses.list.length)];
        final englishBook = verseData['book'] as String;
        final chapterNum = verseData['chapter'] as int;
        final verseNum = verseData['verse'] as int;

        // Translate book name to Malagasy (or whatever BibleService uses)
        final bookName = BibleBookOrder.getDisplayName(englishBook);

        final book = await _bibleService.getBook(bookName);
        if (book == null) {
          if (kDebugMode) {
            print('Book not found: $bookName (English: $englishBook)');
          }
          continue;
        }

        final chapter = book.getChapter(chapterNum);
        if (chapter == null) {
          if (kDebugMode) print('Chapter not found: $chapterNum in $bookName');
          continue;
        }

        final verseText = chapter.verses[verseNum];
        if (verseText == null || verseText.isEmpty) {
          if (kDebugMode) {
            print('Verse not found: $verseNum in $bookName $chapterNum');
          }
          continue;
        }

        return DailyVerse(
          book: bookName,
          chapter: chapterNum,
          verse: verseNum,
          text: verseText,
          reference: '$bookName $chapterNum:$verseNum',
          date: DateTime.now(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting inspiring verse: $e');
      }
    }

    // Fallback: Generate completely random verse if curated list fails
    if (kDebugMode) {
      print('Falling back to random verse generation');
    }

    // Get all books with actual content
    final books = _bibleService.getBooksWithActualContent();
    if (books.isEmpty) {
      throw Exception('No Bible books available');
    }

    // Select random book
    final random = Random();
    final randomBook = books[random.nextInt(books.length)];

    // Get chapters for the book
    final chapters = _bibleService.getChaptersForBook(randomBook);
    if (chapters.isEmpty) {
      throw Exception('No chapters found for book: $randomBook');
    }

    // Select random chapter
    final randomChapter = chapters[random.nextInt(chapters.length)];

    // Get the book and chapter
    final book = await _bibleService.getBook(randomBook);
    if (book == null) {
      throw Exception('Book not found: $randomBook');
    }

    final chapter = book.getChapter(randomChapter);
    if (chapter == null) {
      throw Exception('Chapter not found: $randomChapter in $randomBook');
    }

    // Get verses
    final verses = chapter.verses;
    if (verses.isEmpty) {
      throw Exception('No verses found in $randomBook $randomChapter');
    }

    // Select random verse
    final verseNumbers = verses.keys.toList();
    final randomVerseNumber = verseNumbers[random.nextInt(verseNumbers.length)];
    final verseText = verses[randomVerseNumber] ?? '';

    return DailyVerse(
      book: randomBook,
      chapter: randomChapter,
      verse: randomVerseNumber,
      text: verseText,
      reference: '$randomBook $randomChapter:$randomVerseNumber',
      date: DateTime.now(),
    );
  }

  /// Schedule daily notification at specified time
  Future<void> scheduleDailyNotification(int hour, int minute) async {
    // Cancel existing notifications first
    await cancelDailyNotifications();

    // Get today's verse
    final verse = await getVerseOfTheDay();

    // Create notification
    await DailyVerseNotificationBuilder.scheduleDailyVerse(
      reference: verse.reference,
      text: verse.text,
      book: verse.book,
      chapter: verse.chapter,
      verse: verse.verse,
      hour: hour,
      minute: minute,
    );

    if (kDebugMode) {
      print('Daily verse notification scheduled for $hour:$minute');
    }
  }

  /// Cancel all daily verse notifications
  Future<void> cancelDailyNotifications() async {
    await DailyVerseNotificationBuilder.cancelDailyVerseNotifications();
    if (kDebugMode) {
      print('Daily verse notifications cancelled');
    }
  }

  /// Send test notification immediately
  Future<void> sendTestNotification() async {
    final verse = await getVerseOfTheDay();

    await DailyVerseNotificationBuilder.sendTestNotification(
      reference: verse.reference,
      text: verse.text,
      book: verse.book,
      chapter: verse.chapter,
      verse: verse.verse,
    );
  }
}
