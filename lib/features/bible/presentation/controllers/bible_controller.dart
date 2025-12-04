import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/features/bible/domain/entities/bible_highlight.dart';
import 'package:fihirana/features/bible/domain/entities/bible_search.dart';
import 'package:fihirana/features/bible/data/services/bible_highlight_service.dart';
import 'package:fihirana/features/bible/domain/usecases/initialize_bible_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/get_all_books_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/get_book_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/search_books_usecase.dart';
import 'package:fihirana/core/utils/bible_book_order.dart';

class BibleController extends GetxController {
  final InitializeBibleUseCase _initializeBibleUseCase;
  final GetAllBooksUseCase _getAllBooksUseCase;
  final GetBookUseCase _getBookUseCase;
  
  final SearchBooksUseCase _searchBooksUseCase;
  
  final BibleHighlightService _highlightService = BibleHighlightService();

  BibleController({
    required InitializeBibleUseCase initializeBibleUseCase,
    required GetAllBooksUseCase getAllBooksUseCase,
    required GetBookUseCase getBookUseCase,
    required SearchBooksUseCase searchBooksUseCase,
  })  : _initializeBibleUseCase = initializeBibleUseCase,
        _getAllBooksUseCase = getAllBooksUseCase,
        _getBookUseCase = getBookUseCase,
        _searchBooksUseCase = searchBooksUseCase;

  var selectedBook = ''.obs;
  var selectedChapter = 0.obs;
  var passageText = ''.obs;
  var isLoading = false.obs;
  var loadingMessage = 'Maka boky...'.obs;
  var bookList = <String>[].obs;
  var chapterList = <int>[].obs;

  // Verse selection variables
  var selectedVerses = <int>{}.obs;
  var isSelecting = false.obs;

  // Highlights
  var highlights = <BibleHighlight>[].obs;
  var publicHighlights = <BibleHighlight>[].obs;

  // Filtered books for search
  var filteredBooks = <String>[].obs;

  // Books organized by testament
  var booksByTestament = <String, List<String>>{}.obs;
  var oldTestamentBooks = <String>[].obs;
  var newTestamentBooks = <String>[].obs;

  // Search functionality
  var searchQuery = ''.obs;
  var searchResults = <BibleSearchResult>[].obs;
  var isSearching = false.obs;
  var searchContext = BibleSearchContext.books.obs; // Default to book search
  var searchHistory = <String>[].obs;

  // Verse highlighting for search navigation
  var highlightedVerse = 0.obs;

  // Caching for recently accessed passages
  final Map<String, String> _passageCache = {};
  static const int _maxCacheSize = 50;

  @override
  void onInit() {
    super.onInit();
    _initializeBibleService();
    _loadLastViewedPassage();
  }

Future<void> _initializeBibleService() async {
    isLoading.value = true;
    loadingMessage.value = 'Maka boky...';
    try {
      await _initializeBibleUseCase((message) {
        loadingMessage.value = message;
      });
      // Get all book names and organize by testament
      final allBooks = _getAllBooksUseCase();
      final allBookNames = allBooks.map((book) => book.name).toList();

      // Translate book names to display names if needed
      final translatedBookList = allBookNames
          .map((name) => BibleBookOrder.getDisplayName(name))
          .toList();
      bookList.value = translatedBookList;

// Get books by testament with translated names
      // Note: These methods would need to be added to the repository interface
      // For now, we'll use a simplified approach
      final translatedBooksByTestament = <String, List<String>>{};
      booksByTestament.value = translatedBooksByTestament;

      oldTestamentBooks.value = [];
      newTestamentBooks.value = [];

      // Show books with actual content vs total
      final totalBooks = allBooks.length;

      if (kDebugMode) {
        print('Bible initialization complete:');
        print('  Total books: $totalBooks');
        print('  Books with content: ${allBooks.length}');
        print(
            '  Books with placeholders: ${totalBooks - allBooks.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Bible service: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadLastViewedPassage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBook = prefs.getString('last_bible_book');
      final lastChapter = prefs.getInt('last_bible_chapter');

      // Only load last viewed passage if both book and chapter exist
      if (lastBook != null && lastChapter != null && lastBook.isNotEmpty) {
        // Don't auto-select the book and chapter, let user choose
        // Just populate the book list
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading last viewed passage: $e');
      }
    }
  }

  Future<void> loadPassage() async {
    if (selectedBook.isEmpty || selectedChapter.value == 0) return;

    // Create cache key
    final cacheKey = '${selectedBook.value}_${selectedChapter.value}';

    // Check cache first
    if (_passageCache.containsKey(cacheKey)) {
      passageText.value = _passageCache[cacheKey]!;
      _loadHighlights();
      _saveLastViewedPassage();
      return;
    }

    isLoading.value = true;
    loadingMessage.value =
        'Maka andininy any amin\'i ${selectedBook.value} ${selectedChapter.value}...';
try {
      final book = _getBookUseCase(selectedBook.value);
      final chapter = book?.getChapter(selectedChapter.value);

      if (chapter != null) {
        // Format the chapter text with verse numbers
        final StringBuffer formattedText = StringBuffer();
        chapter.verses.forEach((verseNum, verseText) {
          formattedText.write('$verseNum. $verseText\n\n');
        });

        final text = formattedText.toString();
        passageText.value = text;

        // Add to cache
        _addToCache(cacheKey, text);

        // Load highlights for this chapter
        _loadHighlights();
        _saveLastViewedPassage();
      } else {
        if (kDebugMode) {
          print(
              'Chapter not found: ${selectedChapter.value} in book: ${selectedBook.value}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading passage: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _addToCache(String key, String value) {
    // Remove oldest entry if cache is full
    if (_passageCache.length >= _maxCacheSize) {
      _passageCache.remove(_passageCache.keys.first);
    }

    _passageCache[key] = value;
  }

  void _loadHighlights() {
    if (selectedBook.isEmpty || selectedChapter.value == 0) return;

    // Load user's highlights
    _highlightService
        .getHighlightsStream(selectedBook.value, selectedChapter.value)
        .listen((highlightList) {
      highlights.value = highlightList;
    });

    // Load public highlights
    _highlightService
        .getPublicHighlightsStream(selectedBook.value, selectedChapter.value)
        .listen((highlightList) {
      publicHighlights.value = highlightList;
    });
  }

  Future<void> _saveLastViewedPassage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_bible_book', selectedBook.value);
      await prefs.setInt('last_bible_chapter', selectedChapter.value);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving last viewed passage: $e');
      }
    }
  }

  void selectBook(String bookName) {
    if (kDebugMode) {
      print('Selecting book: $bookName');
    }

// We need to find the actual book name in the cache
    // The display name might be translated, so we need to find the original name
    String actualBookName = bookName;
    final allBooksList = _getAllBooksUseCase();
    final allBookNames = allBooksList.map((book) => book.name).toList();

    // Try to find the book by display name or original name
    for (final cachedBookName in allBookNames) {
      if (BibleBookOrder.getDisplayName(cachedBookName) == bookName ||
          cachedBookName == bookName) {
        actualBookName = cachedBookName;
        break;
      }
    }

    selectedBook.value = actualBookName;
    selectedChapter.value = 0;
    passageText.value = '';

    // Reset verse selection
    clearSelection();

    // Get chapters for the selected book
    final book = _getBookUseCase(actualBookName);
    chapterList.value = book?.chapterData.keys.toList() ?? [];
    if (kDebugMode) {
      print('Chapter list for $actualBookName: ${chapterList.toList()}');
    }
  }

  void selectChapter(int chapter) {
    if (kDebugMode) {
      print('Selecting chapter: $chapter');
    }
    selectedChapter.value = chapter;

    // Reset verse selection
    clearSelection();

    // Clear highlighted verse when changing chapters
    clearHighlightedVerse();

    loadPassage();
  }

  void searchBooks(String query) {
    final books = _searchBooksUseCase(query);
    bookList.value = books.map((book) => book.name).toList();
  }

  void filterBooks(String query) {
    if (query.isEmpty) {
      filteredBooks.clear();
    } else {
      filteredBooks.value = bookList
          .where((book) => book.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

List<String> getAllBooks() {
    final books = _getAllBooksUseCase();
    return books.map((book) => book.name).toList();
  }

Map<String, List<String>> getAllBooksByTestament() {
    final allBooks = _getAllBooksUseCase();
    final bookNames = allBooks.map((book) => book.name).toList();
    return BibleBookOrder.getAllBooksSortedByTestament(bookNames);
  }

  List<String> getOldTestamentBooks() {
    final allBooks = _getAllBooksUseCase();
    final bookNames = allBooks.map((book) => book.name).toList();
    return BibleBookOrder.getSortedOldTestamentBooks(bookNames);
  }

  List<String> getNewTestamentBooks() {
    final allBooks = _getAllBooksUseCase();
    final bookNames = allBooks.map((book) => book.name).toList();
    return BibleBookOrder.getSortedNewTestamentBooks(bookNames);
  }

  // Get only books that have actual Bible content
  List<String> getBooksWithContent() {
    final books = _getAllBooksUseCase();
    return books.map((book) => book.name).toList();
  }

  List<int> getChaptersForSelectedBook() {
    if (selectedBook.isEmpty) return [];
    final book = _getBookUseCase(selectedBook.value);
    return book?.chapterData.keys.toList() ?? [];
  }

  int getChapterCountForBook(String bookName) {
    final book = _getBookUseCase(bookName);
    return book?.chapters ?? 0;
  }



  // ... (existing code)

  // Verse selection methods
  void toggleVerseSelection(int verse) {
    if (selectedVerses.contains(verse)) {
      selectedVerses.remove(verse);
    } else {
      selectedVerses.add(verse);
    }

    isSelecting.value = selectedVerses.isNotEmpty;
  }

  void clearSelection() {
    selectedVerses.clear();
    isSelecting.value = false;
  }

  bool isVerseSelected(int verse) {
    return selectedVerses.contains(verse);
  }

  String getSelectedVerseRange() {
    if (selectedVerses.isEmpty) return '';

    final sortedVerses = selectedVerses.toList()..sort();
    if (sortedVerses.isEmpty) return '';

    // Group into ranges for display
    // This is a simple implementation, can be improved for multiple ranges
    // e.g. "1, 3-5, 8"

    StringBuffer buffer = StringBuffer();
    buffer.write('${selectedBook.value} ${selectedChapter.value}:');

    // Simple comma separated list for now or just the first/last if we want to keep it simple
    // But for display purposes, let's show all selected numbers
    buffer.write(sortedVerses.join(', '));

    return buffer.toString();
  }

  // Highlight methods
  Future<void> saveHighlight() async {
    if (selectedVerses.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar(
        'Fanamarihana',
        'Mila mampiasa compte Google.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Group selected verses into contiguous ranges
    final sortedVerses = selectedVerses.toList()..sort();
    List<List<int>> ranges = [];

    if (sortedVerses.isNotEmpty) {
      List<int> currentRange = [sortedVerses.first];

      for (int i = 1; i < sortedVerses.length; i++) {
        if (sortedVerses[i] == sortedVerses[i - 1] + 1) {
          currentRange.add(sortedVerses[i]);
        } else {
          ranges.add(List.from(currentRange));
          currentRange = [sortedVerses[i]];
        }
      }
      ranges.add(currentRange);
    }

    bool allSuccess = true;

    for (final range in ranges) {
      final highlight = BibleHighlight(
        id: '',
        bookName: selectedBook.value,
        chapter: selectedChapter.value,
        startVerse: range.first,
        endVerse: range.last,
        userId: user.uid,
        userName: user.displayName ?? user.email ?? 'Anonymous',
        color: '#FF0000', // Default red color
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await _highlightService.saveHighlight(highlight);
      if (!success) allSuccess = false;
    }

    if (allSuccess) {
      // Reset selection
      clearSelection();

      // Show success message
      Get.snackbar('Filazana', 'Voatahiry soa aman-tsara!');
    } else {
      Get.snackbar('Filazana', 'Nisy olana teo am-pametrahana.');
    }
  }

  bool isVerseHighlighted(int verse) {
    // Check if verse is in any highlight
    for (final highlight in highlights) {
      if (highlight.containsVerse(verse)) {
        return true;
      }
    }
    return false;
  }

  bool isVerseSearchHighlighted(int verse) {
    return highlightedVerse.value == verse;
  }

  void clearHighlightedVerse() {
    highlightedVerse.value = 0;
  }

  List<String> getCurrentChapterVerses() {
    if (selectedBook.isEmpty || selectedChapter.value == 0) {
      return [];
    }

try {
      final book = _getBookUseCase(selectedBook.value);
      if (book != null) {
        final chapter = book.getChapter(selectedChapter.value);
        if (chapter != null) {
          return chapter.verses.values.toList();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current chapter verses: $e');
      }
    }

    return [];
  }

  // Enhanced search methods
  void setSearchContext(BibleSearchContext context) {
    searchContext.value = context;
    searchResults.clear();
    searchQuery.value = '';
  }

  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) {
      searchResults.clear();
      searchQuery.value = '';
      return;
    }

    isSearching.value = true;
    searchQuery.value = query;

    try {
      switch (searchContext.value) {
        case BibleSearchContext.books:
          await _searchBooks(query);
          break;
        case BibleSearchContext.currentChapter:
          await _searchCurrentChapter(query);
          break;
        case BibleSearchContext.allBible:
          await _searchAllBible(query);
          break;
      }

      // Add to search history
      _addToSearchHistory(query);
    } catch (e) {
      if (kDebugMode) {
        print('Error performing search: $e');
      }
    } finally {
      isSearching.value = false;
    }
  }

Future<void> _searchBooks(String query) async {
    final books = _getAllBooksUseCase();
    final results = books
        .where((book) => book.name.toLowerCase().contains(query.toLowerCase()))
        .map((book) => BibleSearchResult(
              type: BibleSearchResultType.book,
              bookName: book.name,
              chapter: 0,
              verse: 0,
              text: book.name,
              relevance: _calculateRelevance(book.name, query),
            ))
        .toList();

    searchResults.assignAll(results);
  }

Future<void> _searchCurrentChapter(String query) async {
    if (selectedBook.isEmpty || selectedChapter.value == 0) return;

    final book = _getBookUseCase(selectedBook.value);
    if (book == null) return;

    final chapter = book.getChapter(selectedChapter.value);
    if (chapter == null) return;

    final results = <BibleSearchResult>[];
    final lowerQuery = query.toLowerCase();

    chapter.verses.forEach((verseNum, verseText) {
      if (verseText.toLowerCase().contains(lowerQuery)) {
        results.add(BibleSearchResult(
          type: BibleSearchResultType.verse,
          bookName: selectedBook.value,
          chapter: selectedChapter.value,
          verse: verseNum,
          text: verseText,
          relevance: _calculateRelevance(verseText, query),
        ));
      }
    });

    // Sort by relevance
    results.sort((a, b) => b.relevance.compareTo(a.relevance));
    searchResults.assignAll(results);
  }

Future<void> _searchAllBible(String query) async {
    final results = <BibleSearchResult>[];
    final lowerQuery = query.toLowerCase();

    // Search through all books
    final books = _getAllBooksUseCase();
    for (final book in books) {

      // Search through all chapters
      for (final chapterNum in book.chapterData.keys) {
        final chapter = book.getChapter(chapterNum);
        if (chapter == null) continue;

        // Search through all verses
        chapter.verses.forEach((verseNum, verseText) {
          if (verseText.toLowerCase().contains(lowerQuery)) {
            results.add(BibleSearchResult(
              type: BibleSearchResultType.verse,
              bookName: book.name,
              chapter: chapterNum,
              verse: verseNum,
              text: verseText,
              relevance: _calculateRelevance(verseText, query),
            ));
          }
        });
      }
    }

    // Sort by relevance and limit results
    results.sort((a, b) => b.relevance.compareTo(a.relevance));
    searchResults.assignAll(results.take(100).toList()); // Limit to 100 results
  }

  double _calculateRelevance(String text, String query) {
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    double relevance = 0.0;

    // Exact match gets highest relevance
    if (lowerText == lowerQuery) {
      relevance += 100.0;
    }

    // Starts with query gets high relevance
    if (lowerText.startsWith(lowerQuery)) {
      relevance += 50.0;
    }

    // Count occurrences of query in text
    int occurrences = 0;
    int index = lowerText.indexOf(lowerQuery);
    while (index != -1) {
      occurrences++;
      index = lowerText.indexOf(lowerQuery, index + 1);
    }
    relevance += occurrences * 10.0;

    // Shorter text gets slightly higher relevance (more likely to be specific)
    relevance += (100 - text.length) * 0.1;

    return relevance;
  }

  void _addToSearchHistory(String query) {
    if (query.trim().isEmpty) return;

    // Remove if already exists
    searchHistory.remove(query);

    // Add to beginning
    searchHistory.insert(0, query);

    // Keep only last 10 searches
    if (searchHistory.length > 10) {
      searchHistory.removeLast();
    }
  }

  void clearSearchHistory() {
    searchHistory.clear();
  }

  void navigateToSearchResult(BibleSearchResult result, {int? highlightVerse}) {
    switch (result.type) {
      case BibleSearchResultType.book:
        selectBook(result.bookName);
        break;
      case BibleSearchResultType.verse:
        selectBook(result.bookName);
        // Don't clear highlighted verse when selecting chapter
        selectedChapter.value = result.chapter;
        clearSelection();
        loadPassage();

        // Set the verse to highlight AFTER selecting chapter
        if (highlightVerse != null) {
          highlightedVerse.value = highlightVerse;
        }
        break;
    }
  }

  BibleHighlight? getHighlightForVerse(int verse) {
    // Get the highlight that contains this verse
    for (final highlight in highlights) {
      if (highlight.containsVerse(verse)) {
        return highlight;
      }
    }
    return null;
  }

// Clear cache
  void clearCache() {
    _passageCache.clear();
    // Note: clearCache would need to be added to use case or called via repository
  }

  // Debug method
  bool isServiceInitialized() {
    // Note: isInitialized would need to be added to use case or checked via repository
    return true; // Basic implementation
  }

  int getBookCount() {
    final books = _getAllBooksUseCase();
    return books.length;
  }

  Map<String, dynamic> getLoadedBooksInfo() {
    final allBooks = _getAllBooksUseCase();
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
