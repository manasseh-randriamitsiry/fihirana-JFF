import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:fihirana/features/bible/domain/entities/bible.dart';
import 'package:fihirana/core/utils/bible_book_order.dart';
import 'package:fihirana/features/bible/domain/repositories/bible_repository.dart';

class BibleService implements IBibleService {
  static final BibleService _instance = BibleService._internal();
  factory BibleService() => _instance;
  BibleService._internal();

  final Map<String, BibleBook> _bibleCache = {};
  final Map<String, String> _bookFiles = {}; // Maps Malagasy name -> book JSON filename
  final List<String> _loadedBooksLru = []; // Bounded queue for LRU cached books
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
      // Retry using ultra fast loading since it only relies on manifest.json
      await _loadBibleBooksUltraFast();
      _isInitialized = true;
    } finally {
      _isInitializing = false;
      _initializationCompleter?.complete();
    }
  }

  Future<void> _loadBibleBooksUltraFast() async {
    try {
      _onLoadingMessage('Maka lisitry ny boky...');

      // Load manifest file containing book metadata
      final jsonString =
          await rootBundle.loadString('assets/baiboly/manifest.json');
      _onLoadingMessage('Manakatra ny Baiboly...');

      // Parse JSON data
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      if (!jsonData.containsKey('books')) {
        throw Exception('Invalid manifest.json format: missing "books" key');
      }

      final booksData = jsonData['books'] as List<dynamic>;

      _bibleCache.clear();
      _bookFiles.clear();
      _loadedBooksLru.clear();

      for (final bookData in booksData) {
        if (bookData is Map<String, dynamic>) {
          final originalBookName = bookData['name'] as String? ?? 'Unknown Book';
          final fileName = bookData['file'] as String? ?? '';
          final chaptersCount = bookData['chapters'] as int? ?? 0;

          final bookName = BibleBookOrder.getDisplayName(originalBookName);
          
          if (fileName.isNotEmpty) {
            _bookFiles[bookName] = fileName;
          }

          // Create shell book with empty chapterData
          _bibleCache[bookName] = BibleBook(
            name: bookName,
            abbreviation: bookName.length >= 3
                ? bookName.substring(0, 3).toUpperCase()
                : bookName.toUpperCase(),
            chapters: chaptersCount,
            chapterData: {},
          );
        }
      }

      _onLoadingMessage('Vita ny famakiana lisitry ny boky');
    } catch (e) {
      _onLoadingMessage('Nisy olana tamin\'ny famakiana Baiboly: $e');
      rethrow;
    }
  }

  @override
  Future<void> loadBookContent(String bookName) async {
    final book = _bibleCache[bookName];
    if (book == null) return;
    
    // If book is already fully loaded, just update its LRU status
    if (book.chapterData.isNotEmpty) {
      _loadedBooksLru.remove(bookName);
      _loadedBooksLru.add(bookName);
      return;
    }

    final file = _bookFiles[bookName];
    if (file == null) return;

    try {
      if (kDebugMode) {
        print('📖 Lazy loading Bible book: $bookName from $file');
      }

      final jsonString =
          await rootBundle.loadString('assets/baiboly/books/$file');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      // Parse and populate chapterData in place
      if (jsonData.containsKey('chapters')) {
        final chaptersList = jsonData['chapters'] as List<dynamic>;
        for (final chapterData in chaptersList) {
          if (chapterData is Map<String, dynamic>) {
            final chapterNum = chapterData['chapter'] as int? ?? 0;
            if (chapterNum > 0) {
              book.chapterData[chapterNum] =
                  BibleChapter.fromJson(chapterData, chapterNum);
            }
          }
        }
      } else {
        jsonData.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final chapterNum = int.tryParse(key);
            if (chapterNum != null) {
              book.chapterData[chapterNum] =
                  BibleChapter.fromJson(value, chapterNum);
            }
          }
        });
      }

      // LRU cache eviction - keep maximum 3 books in memory
      _loadedBooksLru.remove(bookName);
      _loadedBooksLru.add(bookName);

      if (_loadedBooksLru.length > 3) {
        final oldestBookName = _loadedBooksLru.first;
        final oldestBook = _bibleCache[oldestBookName];
        if (oldestBook != null && oldestBookName != bookName) {
          if (kDebugMode) {
            print('🧹 Bounded Eviction: Clearing cached Bible book: $oldestBookName');
          }
          oldestBook.chapterData.clear();
          _loadedBooksLru.remove(oldestBookName);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error lazy loading book $bookName: $e');
      }
    }
  }

  // Check if a book has actual content (not just placeholder text)
  bool _bookHasContent(BibleBook book) {
    if (book.chapterData.isEmpty) return true; // Assume true if shell in manifest
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
  @override
  Map<String, List<String>> getAllBooksByTestament() {
    final allBooks = _bibleCache.keys.toList();
    return BibleBookOrder.getAllBooksSortedByTestament(allBooks);
  }

// Get only Old Testament books in order
  @override
  List<String> getOldTestamentBooks() {
    final allBooks = _bibleCache.keys.toList();
    final oldTestamentBooks =
        allBooks.where(BibleBookOrder.isOldTestamentBook).toList();
    return BibleBookOrder.getSortedOldTestamentBooks(oldTestamentBooks);
  }

// Get only New Testament books in order
  @override
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

  @override
  Map<String, dynamic> getLoadedBooksInfo() {
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
  Future<List<VerseSearchResult>> searchVerses(String query) async {
    final results = <VerseSearchResult>[];
    if (query.trim().isEmpty) return results;

    final lowerQuery = query.toLowerCase();

    // Search books one-by-one to avoid out-of-memory issues
    for (final bookName in getAllBookNames()) {
      final file = _bookFiles[bookName];
      if (file == null) continue;

      final cachedBook = _bibleCache[bookName];
      if (cachedBook == null) continue;

      bool wasCached = cachedBook.chapterData.isNotEmpty;

      if (!wasCached) {
        try {
          final jsonString =
              await rootBundle.loadString('assets/baiboly/books/$file');
          final jsonData = json.decode(jsonString) as Map<String, dynamic>;

          if (jsonData.containsKey('chapters')) {
            final chaptersList = jsonData['chapters'] as List<dynamic>;
            for (final chapterData in chaptersList) {
              if (chapterData is Map<String, dynamic>) {
                final chapterNum = chapterData['chapter'] as int? ?? 0;
                if (chapterNum > 0) {
                  cachedBook.chapterData[chapterNum] =
                      BibleChapter.fromJson(chapterData, chapterNum);
                }
              }
            }
          } else {
            jsonData.forEach((key, value) {
              if (value is Map<String, dynamic>) {
                final chapterNum = int.tryParse(key);
                if (chapterNum != null) {
                  cachedBook.chapterData[chapterNum] =
                      BibleChapter.fromJson(value, chapterNum);
                }
              }
            });
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error loading book $bookName for search: $e');
          }
          continue;
        }
      }

      for (final chapterEntry in cachedBook.chapterData.entries) {
        final chapterNum = chapterEntry.key;
        final chapterData = chapterEntry.value;
        for (final verseEntry in chapterData.verses.entries) {
          final verseNum = verseEntry.key;
          final verseText = verseEntry.value;

          if (verseText.toLowerCase().contains(lowerQuery)) {
            results.add(VerseSearchResult(
              bookName: bookName,
              chapter: chapterNum,
              verse: verseNum,
              text: verseText,
            ));
          }
        }
      }

      // Evict from memory if it wasn't previously cached
      if (!wasCached) {
        cachedBook.chapterData.clear();
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
    final loadedBooks = _bibleCache.values.where((b) => b.chapterData.isNotEmpty).toList();
    if (loadedBooks.isEmpty) {
      return VerseSearchResult(
        bookName: 'Genesis',
        chapter: 1,
        verse: 1,
        text: 'Tahian\'Andriamanitra ianao.',
      );
    }
    
    loadedBooks.shuffle();
    final book = loadedBooks.first;
    final chapters = book.chapterData.keys.toList();
    if (chapters.isEmpty) return getRandomVerse();
    
    chapters.shuffle();
    final chapterNum = chapters.first;
    final chapter = book.getChapter(chapterNum);
    
    if (chapter == null || chapter.verses.isEmpty) return getRandomVerse();
    
    final verseEntries = chapter.verses.entries.toList();
    verseEntries.shuffle();
    final verse = verseEntries.first;
    
    return VerseSearchResult(
      bookName: book.name,
      chapter: chapterNum,
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
