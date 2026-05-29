import 'package:fihirana/features/bible/domain/entities/bible.dart';

/// Abstract interface for Bible service operations
/// This allows for dependency injection and better testability
abstract class IBibleService {
  /// Check if the service is initialized
  bool get isInitialized;
  
  /// Initialize the Bible service with optional loading callback
  Future<void> initialize([Function(String)? loadingCallback]);
  
  /// Get all Bible books
  List<BibleBook> getAllBooks();
  
  /// Get a specific Bible book by name
  BibleBook? getBook(String bookName);
  
  /// Get a specific chapter from a book
  BibleChapter? getChapter(String bookName, int chapterNumber);
  
  /// Get a specific verse
  String? getVerse(String bookName, int chapterNumber, int verseNumber);
  
  /// Search for verses containing the given text
  Future<List<VerseSearchResult>> searchVerses(String query);

  /// Load book content asynchronously
  Future<void> loadBookContent(String bookName);
  
  /// Get books that contain the search query
  List<BibleBook> searchBooks(String query);
  
  /// Get the total number of books
  int get bookCount;
  
  /// Get the total number of chapters in a book
  int getChapterCount(String bookName);
  
  /// Get the total number of verses in a chapter
  int getVerseCount(String bookName, int chapterNumber);
  
  /// Get random verse
  VerseSearchResult? getRandomVerse();
  
  /// Get verses for a range (e.g., Genesis 1:1-5)
  List<VerseSearchResult> getVerseRange(String bookName, int chapterNumber, int startVerse, int endVerse);
  
  /// Check if a book exists
  bool hasBook(String bookName);
  
  /// Check if a chapter exists
  bool hasChapter(String bookName, int chapterNumber);
  
  /// Check if a verse exists
  bool hasVerse(String bookName, int chapterNumber, int verseNumber);
  
  /// Get book order index
  int getBookOrder(String bookName);
  
  /// Clear cache (for testing purposes)
  void clearCache();
  
  /// Preload books for better performance
  Future<void> preloadBooks(List<String> bookNames);
  
  /// Get all books organized by testament
  Map<String, List<String>> getAllBooksByTestament();
  
  /// Get Old Testament books
  List<String> getOldTestamentBooks();
  
  /// Get New Testament books
  List<String> getNewTestamentBooks();
  
  /// Get information about loaded books
  Map<String, dynamic> getLoadedBooksInfo();
}

/// Result of a verse search operation
class VerseSearchResult {
  final String bookName;
  final int chapter;
  final int verse;
  final String text;
  
  VerseSearchResult({
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
  });
  
  @override
  String toString() => '$bookName $chapter:$verse - $text';
}