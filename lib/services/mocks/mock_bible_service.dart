import 'dart:async';
import 'package:fihirana/models/bible.dart';
import '../interfaces/ibible_service.dart';

/// Mock implementation of BibleService for testing
class MockBibleService implements IBibleService {
  @override
  bool get isInitialized => _isInitialized;
  bool _isInitialized = false;

  final Map<String, BibleBook> _mockBooks = {};

  MockBibleService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Add some mock Bible books for testing
    _mockBooks['Genesis'] = BibleBook(
      name: 'Genesis',
      abbreviation: 'GEN',
      chapters: 1,
      chapterData: {
        1: BibleChapter(
          number: 1,
          verses: {
            1: 'In the beginning God created the heavens and the earth.',
            2: 'Now the earth was formless and empty...',
          },
        ),
      },
    );
    
    _mockBooks['John'] = BibleBook(
      name: 'John',
      abbreviation: 'JHN',
      chapters: 1,
      chapterData: {
        1: BibleChapter(
          number: 1,
          verses: {
            1: 'In the beginning was the Word...',
            2: 'He was with God in the beginning.',
          },
        ),
      },
    );
  }

  @override
  Future<void> initialize([Function(String)? loadingCallback]) async {
    loadingCallback?.call('Initializing mock Bible service...');
    await Future.delayed(const Duration(milliseconds: 100));
    _isInitialized = true;
  }

  @override
  List<BibleBook> getAllBooks() {
    return _mockBooks.values.toList();
  }

  @override
  BibleBook? getBook(String bookName) {
    return _mockBooks[bookName];
  }

  @override
  BibleChapter? getChapter(String bookName, int chapterNumber) {
    final book = getBook(bookName);
    if (book == null) return null;
    
    return book.chapterData[chapterNumber];
  }

  @override
  String? getVerse(String bookName, int chapterNumber, int verseNumber) {
    final chapter = getChapter(bookName, chapterNumber);
    if (chapter == null) return null;
    
    return chapter.verses[verseNumber];
  }

  @override
  List<VerseSearchResult> searchVerses(String query) {
    final results = <VerseSearchResult>[];
    final lowerQuery = query.toLowerCase();
    
    for (final book in _mockBooks.values) {
      for (final chapter in book.chapterData.values) {
        for (final verseEntry in chapter.verses.entries) {
          if (verseEntry.value.toLowerCase().contains(lowerQuery)) {
            results.add(VerseSearchResult(
              bookName: book.name,
              chapter: chapter.number,
              verse: verseEntry.key,
              text: verseEntry.value,
            ));
          }
        }
      }
    }
    
    return results;
  }

  @override
  List<BibleBook> searchBooks(String query) {
    final lowerQuery = query.toLowerCase();
    return _mockBooks.values.where((book) => 
      book.name.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  @override
  int get bookCount => _mockBooks.length;

  @override
  int getChapterCount(String bookName) {
    final book = getBook(bookName);
    return book?.chapters ?? 0;
  }

  @override
  int getVerseCount(String bookName, int chapterNumber) {
    final chapter = getChapter(bookName, chapterNumber);
    return chapter?.verses.length ?? 0;
  }

  @override
  VerseSearchResult? getRandomVerse() {
    final allVerses = <VerseSearchResult>[];
    for (final book in _mockBooks.values) {
      for (final chapter in book.chapterData.values) {
        for (final verseEntry in chapter.verses.entries) {
          allVerses.add(VerseSearchResult(
            bookName: book.name,
            chapter: chapter.number,
            verse: verseEntry.key,
            text: verseEntry.value,
          ));
        }
      }
    }
    
    if (allVerses.isEmpty) return null;
    
    allVerses.shuffle();
    return allVerses.first;
  }

  @override
  List<VerseSearchResult> getVerseRange(String bookName, int chapterNumber, int startVerse, int endVerse) {
    final chapter = getChapter(bookName, chapterNumber);
    if (chapter == null) return [];
    
    final results = <VerseSearchResult>[];
    for (int i = startVerse; i <= endVerse; i++) {
      final verseText = chapter.verses[i];
      if (verseText != null) {
        results.add(VerseSearchResult(
          bookName: bookName,
          chapter: chapterNumber,
          verse: i,
          text: verseText,
        ));
      }
    }
    
    return results;
  }

  @override
  bool hasBook(String bookName) {
    return _mockBooks.containsKey(bookName);
  }

  @override
  bool hasChapter(String bookName, int chapterNumber) {
    final book = getBook(bookName);
    if (book == null) return false;
    
    return book.chapterData.containsKey(chapterNumber);
  }

  @override
  bool hasVerse(String bookName, int chapterNumber, int verseNumber) {
    final verse = getVerse(bookName, chapterNumber, verseNumber);
    return verse != null;
  }

  @override
  int getBookOrder(String bookName) {
    final books = getAllBooks();
    final index = books.indexWhere((b) => b.name == bookName);
    return index >= 0 ? index : -1;
  }

  @override
  void clearCache() {
    _mockBooks.clear();
    _initializeMockData();
  }

  @override
  Future<void> preloadBooks(List<String> bookNames) async {
    // Mock preloading
    await Future.delayed(const Duration(milliseconds: 50));
  }
}