import 'package:fihirana/features/bible/domain/entities/bible.dart';
import 'package:fihirana/features/bible/domain/repositories/bible_repository.dart';
import 'package:fihirana/features/bible/data/services/bible_service.dart';
import 'package:fihirana/core/utils/bible_book_order.dart';

class BibleRepositoryImpl implements IBibleService {
  final BibleService _bibleService;

  BibleRepositoryImpl(this._bibleService);

  @override
  bool get isInitialized => _bibleService.isInitialized;

  @override
  Future<void> initialize([Function(String)? loadingCallback]) {
    return _bibleService.initialize(loadingCallback);
  }

  @override
  List<BibleBook> getAllBooks() {
    return _bibleService.getAllBooks();
  }

  @override
  BibleBook? getBook(String bookName) {
    return _bibleService.getBook(bookName);
  }

  @override
  BibleChapter? getChapter(String bookName, int chapterNumber) {
    return _bibleService.getChapter(bookName, chapterNumber);
  }

  @override
  String? getVerse(String bookName, int chapterNumber, int verseNumber) {
    return _bibleService.getVerse(bookName, chapterNumber, verseNumber);
  }

  @override
  List<VerseSearchResult> searchVerses(String query) {
    return _bibleService.searchVerses(query);
  }

  @override
  List<BibleBook> searchBooks(String query) {
    return _bibleService.searchBooks(query);
  }

  @override
  int get bookCount => _bibleService.bookCount;

  @override
  int getChapterCount(String bookName) {
    return _bibleService.getChapterCount(bookName);
  }

  @override
  int getVerseCount(String bookName, int chapterNumber) {
    return _bibleService.getVerseCount(bookName, chapterNumber);
  }

  @override
  VerseSearchResult? getRandomVerse() {
    return _bibleService.getRandomVerse();
  }

  @override
  List<VerseSearchResult> getVerseRange(String bookName, int chapterNumber, int startVerse, int endVerse) {
    return _bibleService.getVerseRange(bookName, chapterNumber, startVerse, endVerse);
  }

  @override
  bool hasBook(String bookName) {
    return _bibleService.hasBook(bookName);
  }

  @override
  bool hasChapter(String bookName, int chapterNumber) {
    return _bibleService.hasChapter(bookName, chapterNumber);
  }

  @override
  bool hasVerse(String bookName, int chapterNumber, int verseNumber) {
    return _bibleService.hasVerse(bookName, chapterNumber, verseNumber);
  }

  @override
  int getBookOrder(String bookName) {
    return _bibleService.getBookOrder(bookName);
  }

  @override
  void clearCache() {
    _bibleService.clearCache();
  }

  @override
  Future<void> preloadBooks(List<String> bookNames) {
    return _bibleService.preloadBooks(bookNames);
  }

  @override
  Map<String, List<String>> getAllBooksByTestament() {
    final allBooks = getAllBooks();
    final bookNames = allBooks.map((book) => book.name).toList();
    return BibleBookOrder.getAllBooksSortedByTestament(bookNames);
  }

  @override
  List<String> getOldTestamentBooks() {
    final allBooks = getAllBooks();
    final bookNames = allBooks.map((book) => book.name).toList();
    return BibleBookOrder.getSortedOldTestamentBooks(bookNames);
  }

  @override
  List<String> getNewTestamentBooks() {
    final allBooks = getAllBooks();
    final bookNames = allBooks.map((book) => book.name).toList();
    return BibleBookOrder.getSortedNewTestamentBooks(bookNames);
  }

  @override
  Map<String, dynamic> getLoadedBooksInfo() {
    final allBooks = getAllBooks();
    final bookNames = allBooks.map((book) => book.name).toList();
    final testamentOrganization = getAllBooksByTestament();
    
    return {
      'totalBooks': allBooks.length,
      'bookNames': bookNames,
      'oldTestamentBooks': testamentOrganization['Testameta Taloha'] ?? [],
      'newTestamentBooks': testamentOrganization['Testameta Vaovao'] ?? [],
      'oldTestamentCount': (testamentOrganization['Testameta Taloha'] as List?)?.length ?? 0,
      'newTestamentCount': (testamentOrganization['Testameta Vaovao'] as List?)?.length ?? 0,
    };
  }
}