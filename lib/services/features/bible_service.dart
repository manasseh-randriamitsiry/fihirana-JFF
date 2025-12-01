import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:fihirana/models/bible.dart';
import 'package:fihirana/utility/bible_book_order.dart';
import 'package:fihirana/services/interfaces/ibible_service.dart';

class BibleService implements IBibleService {
  static final BibleService _instance = BibleService._internal();
  factory BibleService() => _instance;
  BibleService._internal();

  final Map<String, BibleBook> _bibleCache = {};
  bool _isInitialized = false;
  bool _isInitializing = false;
  Function(String)? onLoadingMessage; // Callback for loading messages
  Completer<void>? _initializationCompleter;

  @override
  Future<void> initialize([Function(String)? loadingCallback]) async {
    // If already initialized, return immediately
    if (_isInitialized) return;

    // If initialization is in progress, wait for it to complete
    if (_isInitializing) {
      await _initializationCompleter?.future;
      return;
    }

    // Start initialization
    _isInitializing = true;
    _initializationCompleter = Completer<void>();
    onLoadingMessage = loadingCallback;

    try {
      await _loadBibleBooksUltraFast();
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Bible service initialization failed: $e');
      }
      // Try fallback initialization
      await _loadBibleBooksFallback();
      _isInitialized = true;
    } finally {
      _isInitializing = false;
      _initializationCompleter?.complete();
    }
  }

  Future<void> _loadBibleBooksUltraFast() async {
    try {
      _onLoadingMessage('Maka Baiboly iray manontolo...');

      // Load single bible.json file
      final jsonString =
          await rootBundle.loadString('assets/baiboly/bible.json');
      _onLoadingMessage('Manakatra ny Baiboly...');

      // Parse JSON data
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      if (!jsonData.containsKey('books')) {
        throw Exception('Invalid bible.json format: missing "books" key');
      }

      final booksData = jsonData['books'] as List<dynamic>;
      final totalBooks = booksData.length;

      _onLoadingMessage('Mamaky boky $totalBooks...');

      // Parse all books in batches to avoid memory issues
      const batchSize = 10;
      var loadedBooks = 0;

      for (var i = 0; i < booksData.length; i += batchSize) {
        final end = (i + batchSize < booksData.length)
            ? i + batchSize
            : booksData.length;
        final batch = booksData.sublist(i, end);

        // Parse batch in parallel
        final parseFutures = batch.map((bookData) async {
          try {
            final bookMap = bookData as Map<String, dynamic>;

            // Extract book name from data
            final originalBookName =
                bookMap['name'] as String? ?? 'Unknown Book';

            // Translate English book names to Malagasy for consistency
            final bookName = BibleBookOrder.getDisplayName(originalBookName);

            // Create BibleBook directly from book data
            final book = BibleBook.fromJson(bookMap, bookName);
            return book;
          } catch (e) {
            if (kDebugMode) {
              print('Failed to parse book: $e');
            }
            return null;
          }
        }).toList();

        // Wait for parsing to complete
        final parsedBooks = await Future.wait(parseFutures);

        // Add successfully parsed books to cache
        for (final book in parsedBooks) {
          if (book != null) {
            _bibleCache[book.name] = book;
            loadedBooks++;
            if (loadedBooks % 3 == 0) {
              // Update every 3 books to reduce UI updates
              _onLoadingMessage('Voakija: $loadedBooks/$totalBooks boky');
            }
          }
        }

        // Add a small delay to prevent blocking UI
        await Future.delayed(const Duration(milliseconds: 10));
      }

      _onLoadingMessage('Vita ny famakiana Baiboly ($loadedBooks/$totalBooks)');
    } catch (e) {
      _onLoadingMessage('Nisy olana tamin\'ny famakiana Baiboly: $e');
      rethrow; // Re-throw to trigger fallback
    }
  }

  // Check if a book has actual content (not just placeholder text)
  bool _bookHasContent(BibleBook book) {
    for (final chapter in book.chapterData.values) {
      for (final verseText in chapter.verses.values) {
        // Check if verse contains actual content (not just placeholder)
        if (verseText.isNotEmpty &&
            !verseText.contains('[Tsy misy soratra') &&
            !verseText.contains('Ampidiro eto ny teny malagasy')) {
          return true;
        }
      }
    }
    return false;
  }

  // Get books with actual content
  List<String> getBooksWithContent() {
    return _bibleCache.entries
        .where((entry) => _bookHasContent(entry.value))
        .map((entry) => entry.key)
        .toList();
  }

  Future<void> _loadBibleBooksFallback() async {
    try {
      _onLoadingMessage('Maka Baiboly (fallback)...');

      // Fallback method: Try to load single bible.json file directly
      final jsonString =
          await rootBundle.loadString('assets/baiboly/bible.json');
      _onLoadingMessage('Manakatra ny Baiboly (fallback)...');

      // Parse JSON data
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      if (!jsonData.containsKey('books')) {
        throw Exception('Invalid bible.json format: missing "books" key');
      }

      final booksData = jsonData['books'] as List<dynamic>;
      final totalBooks = booksData.length;
      var loadedBooks = 0;

      _onLoadingMessage('Mamaky boky ($totalBooks boky)...');

      // Parse books one by one for fallback
      for (final bookData in booksData) {
        try {
          final bookMap = bookData as Map<String, dynamic>;
          final bookName = bookMap['name'] as String? ?? 'Unknown Book';

          final book = BibleBook.fromJson(bookMap, bookName);
          _bibleCache[book.name] = book;
          loadedBooks++;

          if (loadedBooks % 3 == 0) {
            _onLoadingMessage('Voakija: $loadedBooks/$totalBooks boky');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to parse book in fallback: $e');
          }
          continue;
        }
      }

      _onLoadingMessage('Vita ny famakiana Baiboly ($loadedBooks/$totalBooks)');
    } catch (e) {
      _onLoadingMessage(
          'Nisy olana tamin\'ny famakiana Baiboly (fallback): $e');
    }
  }

  void _onLoadingMessage(String message) {
    if (onLoadingMessage != null) {
      // Debounce loading messages to reduce UI updates
      onLoadingMessage!(message);
    }
  }

  // Get all Bible books
  @override
  List<BibleBook> getAllBooks() {
    return _bibleCache.values.toList();
  }

  // Get a specific book by name
  BibleBook? getBookByName(String bookName) {
    return _bibleCache[bookName];
  }

  // Check if service is initialized
  @override
  bool get isInitialized => _isInitialized;

  // New methods needed by BibleController
  List<String> getAllBookNames() {
    final allBooks = _bibleCache.keys.toList();
    // Sort by biblical order instead of alphabetical
    allBooks.sort((a, b) => BibleBookOrder.getBookOrderPosition(a)
        .compareTo(BibleBookOrder.getBookOrderPosition(b)));
    return allBooks;
  }

  // Get books organized by testament
  Map<String, List<String>> getAllBooksByTestament() {
    final allBooks = _bibleCache.keys.toList();
    return BibleBookOrder.getAllBooksSortedByTestament(allBooks);
  }

  // Get only Old Testament books in order
  List<String> getOldTestamentBooks() {
    final allBooks = _bibleCache.keys.toList();
    final oldTestamentBooks =
        allBooks.where(BibleBookOrder.isOldTestamentBook).toList();
    return BibleBookOrder.getSortedOldTestamentBooks(oldTestamentBooks);
  }

  // Get only New Testament books in order
  List<String> getNewTestamentBooks() {
    final allBooks = _bibleCache.keys.toList();
    final newTestamentBooks =
        allBooks.where(BibleBookOrder.isNewTestamentBook).toList();
    return BibleBookOrder.getSortedNewTestamentBooks(newTestamentBooks);
  }

  @override
  BibleBook? getBook(String bookName) {
    return _bibleCache[bookName];
  }

  BibleBook? getBookSync(String bookName) {
    return _bibleCache[bookName];
  }

  List<int> getChaptersForBook(String bookName) {
    final book = _bibleCache[bookName];
    if (book != null) {
      return book.chapterData.keys.toList()..sort();
    }
    return [];
  }

  @override
  List<BibleBook> searchBooks(String query) {
    if (query.isEmpty) {
      return _bibleCache.values.toList();
    }

    final filteredBooks = _bibleCache.values
        .where((book) => book.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    // Sort by biblical order instead of alphabetical
    filteredBooks.sort((a, b) => BibleBookOrder.getBookOrderPosition(a.name)
        .compareTo(BibleBookOrder.getBookOrderPosition(b.name)));
    return filteredBooks;
  }

  @override
  void clearCache() {
    _bibleCache.clear();
    _isInitialized = false;
    _isInitializing = false;
  }

  int getBookCount() {
    return _bibleCache.length;
  }

  Map<String, int> getLoadedBooksInfo() {
    final Map<String, int> info = {};
    _bibleCache.forEach((name, book) {
      info[name] = book.chapters;
    });
    return info;
  }

  // Get books that have actual Bible content (not placeholders)
  List<String> getBooksWithActualContent() {
    return _bibleCache.entries
        .where((entry) => _bookHasContent(entry.value))
        .map((entry) => entry.key)
        .toList();
  }

  // Check if a specific book has content
  bool bookHasContent(String bookName) {
    final book = _bibleCache[bookName];
    if (book == null) return false;
    return _bookHasContent(book);
  }

  // Get placeholder status for a book
  String getBookStatus(String bookName) {
    final book = _bibleCache[bookName];
    if (book == null) return 'Unknown';

    if (_bookHasContent(book)) {
      return 'Complete';
    } else {
      return 'Placeholder';
    }
  }

  // Get books grouped by status
  Map<String, List<String>> getBooksByStatus() {
    final Map<String, List<String>> result = {
      'Complete': [],
      'Placeholder': []
    };

    _bibleCache.forEach((name, book) {
      if (_bookHasContent(book)) {
        result['Complete']!.add(name);
      } else {
        result['Placeholder']!.add(name);
      }
    });

    return result;
  }

  @override
  BibleChapter? getChapter(String bookName, int chapterNumber) {
    final book = _bibleCache[bookName];
    if (book == null) return null;
    return book.getChapter(chapterNumber);
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
    for (final book in _bibleCache.values) {
      for (int chapter = 1; chapter <= book.chapters; chapter++) {
        final chapterData = book.getChapter(chapter);
        if (chapterData != null) {
          for (final entry in chapterData.verses.entries) {
            if (entry.value.toLowerCase().contains(query.toLowerCase())) {
              results.add(VerseSearchResult(
                bookName: book.name,
                chapter: chapter,
                verse: entry.key,
                text: entry.value,
              ));
            }
          }
        }
      }
    }
    return results;
  }

  @override
  int get bookCount => _bibleCache.length;

  @override
  int getChapterCount(String bookName) {
    final book = _bibleCache[bookName];
    return book?.chapters ?? 0;
  }

  @override
  int getVerseCount(String bookName, int chapterNumber) {
    final chapter = getChapter(bookName, chapterNumber);
    return chapter?.verses.length ?? 0;
  }

  @override
  VerseSearchResult? getRandomVerse() {
    final books = _bibleCache.values.where(_bookHasContent).toList();
    if (books.isEmpty) return null;
    
    books.shuffle();
    final book = books.first;
    final chapterNumber = (book.chapters * (DateTime.now().millisecond % 1000) / 1000).floor() + 1;
    final chapter = book.getChapter(chapterNumber);
    
    if (chapter == null || chapter.verses.isEmpty) return getRandomVerse();
    
    final verseEntries = chapter.verses.entries.toList();
    verseEntries.shuffle();
    final verse = verseEntries.first;
    
    return VerseSearchResult(
      bookName: book.name,
      chapter: chapterNumber,
      verse: verse.key,
      text: verse.value,
    );
  }

  @override
  List<VerseSearchResult> getVerseRange(String bookName, int chapterNumber, int startVerse, int endVerse) {
    final results = <VerseSearchResult>[];
    final chapter = getChapter(bookName, chapterNumber);
    if (chapter == null) return results;
    
    for (int verse = startVerse; verse <= endVerse; verse++) {
      final text = chapter.verses[verse];
      if (text != null) {
        results.add(VerseSearchResult(
          bookName: bookName,
          chapter: chapterNumber,
          verse: verse,
          text: text,
        ));
      }
    }
    return results;
  }

  @override
  bool hasBook(String bookName) {
    return _bibleCache.containsKey(bookName);
  }

  @override
  bool hasChapter(String bookName, int chapterNumber) {
    final book = _bibleCache[bookName];
    if (book == null) return false;
    return chapterNumber >= 1 && chapterNumber <= book.chapters;
  }

  @override
  bool hasVerse(String bookName, int chapterNumber, int verseNumber) {
    final chapter = getChapter(bookName, chapterNumber);
    return chapter?.verses.containsKey(verseNumber) ?? false;
  }

  @override
  int getBookOrder(String bookName) {
    return BibleBookOrder.getBookOrderPosition(bookName);
  }

  @override
  Future<void> preloadBooks(List<String> bookNames) async {
    // Books are already loaded during initialization
    // This method can be used for future optimization
  }
}
