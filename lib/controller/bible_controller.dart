import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible_highlight.dart';
import '../models/bible_search.dart';
import '../services/bible_service.dart';
import '../services/bible_highlight_service.dart';

class BibleController extends GetxController {
  final BibleService _bibleService = BibleService();
  final BibleHighlightService _highlightService = BibleHighlightService();

  var selectedBook = ''.obs;
  var selectedChapter = 0.obs;
  var passageText = ''.obs;
  var isLoading = false.obs;
  var loadingMessage = 'Maka boky...'.obs;
  var bookList = <String>[].obs;
  var chapterList = <int>[].obs;

  // Verse selection variables
  var startVerse = 0.obs;
  var endVerse = 0.obs;
  var isSelecting = false.obs;

  // Highlights
  var highlights = <BibleHighlight>[].obs;
  var publicHighlights = <BibleHighlight>[].obs;

  // Filtered books for search
  var filteredBooks = <String>[].obs;
  
  // Search functionality
  var searchQuery = ''.obs;
  var searchResults = <BibleSearchResult>[].obs;
  var isSearching = false.obs;
  var searchContext = BibleSearchContext.books.obs; // Default to book search
  var searchHistory = <String>[].obs;

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
      await _bibleService.initialize((message) {
        loadingMessage.value = message;
      });
      // Get all book names
      bookList.value = _bibleService.getAllBookNames();
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
      final book = await _bibleService.getBook(selectedBook.value);
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
    selectedBook.value = bookName;
    selectedChapter.value = 0;
    passageText.value = '';

    // Reset verse selection
    startVerse.value = 0;
    endVerse.value = 0;
    isSelecting.value = false;

    // Get chapters for the selected book
    chapterList.value = _bibleService.getChaptersForBook(bookName);
    if (kDebugMode) {
      print('Chapter list for $bookName: ${chapterList.value}');
    }
  }

  void selectChapter(int chapter) {
    if (kDebugMode) {
      print('Selecting chapter: $chapter');
    }
    selectedChapter.value = chapter;

    // Reset verse selection
    startVerse.value = 0;
    endVerse.value = 0;
    isSelecting.value = false;

    loadPassage();
  }

  void searchBooks(String query) {
    bookList.value = _bibleService.searchBooks(query);
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
    return _bibleService.getAllBookNames();
  }

  List<int> getChaptersForSelectedBook() {
    if (selectedBook.isEmpty) return [];
    return _bibleService.getChaptersForBook(selectedBook.value);
  }

  int getChapterCountForBook(String bookName) {
    return _bibleService.getChaptersForBook(bookName).length;
  }

  // Verse selection methods
  void startVerseSelection(int verse) {
    startVerse.value = verse;
    endVerse.value = verse;
    isSelecting.value = true;
  }

  void updateVerseSelection(int verse) {
    if (isSelecting.value) {
      if (verse >= startVerse.value) {
        endVerse.value = verse;
      } else {
        endVerse.value = startVerse.value;
        startVerse.value = verse;
      }
    }
  }

  void endVerseSelection() {
    isSelecting.value = false;
  }

  bool isVerseSelected(int verse) {
    return verse >= startVerse.value &&
            verse <= endVerse.value &&
            isSelecting.value ||
        (verse == startVerse.value &&
            startVerse.value == endVerse.value &&
            isSelecting.value);
  }

  String getSelectedVerseRange() {
    if (startVerse.value == 0 || endVerse.value == 0) return '';
    if (startVerse.value == endVerse.value) {
      return '${selectedBook.value} ${selectedChapter.value}:${startVerse.value}';
    } else {
      return '${selectedBook.value} ${selectedChapter.value}:${startVerse.value}-${endVerse.value}';
    }
  }

  // Highlight methods
  Future<void> saveHighlight() async {
    if (startVerse.value == 0 || endVerse.value == 0) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final highlight = BibleHighlight(
      id: '',
      bookName: selectedBook.value,
      chapter: selectedChapter.value,
      startVerse: startVerse.value,
      endVerse: endVerse.value,
      userId: user.uid,
      userName: user.displayName ?? user.email ?? 'Anonymous',
      color: '#FF0000', // Default red color
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await _highlightService.saveHighlight(highlight);
    if (success) {
      // Reset selection
      startVerse.value = 0;
      endVerse.value = 0;
      isSelecting.value = false;

      // Show success message
      Get.snackbar('Fametrahana', 'Voatahiry soa aman-tsara ny famaritaka!');
    } else {
      Get.snackbar(
          'Fametrahana', 'Nisy olana teo am-pametrahana ny famaritaka.');
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

  // New methods for enhanced screen
  void toggleVerseSelection(int verse) {
    if (startVerse.value == 0) {
      // Start new selection
      startVerse.value = verse;
      endVerse.value = verse;
      isSelecting.value = true;
    } else if (verse == startVerse.value && verse == endVerse.value) {
      // Deselect if clicking the same verse
      startVerse.value = 0;
      endVerse.value = 0;
      isSelecting.value = false;
    } else if (verse >= startVerse.value && verse <= endVerse.value) {
      // Extend or shrink selection
      if (verse == startVerse.value) {
        startVerse.value = verse + 1;
      } else if (verse == endVerse.value) {
        endVerse.value = verse - 1;
      } else {
        // Select within range - shrink to this verse
        startVerse.value = verse;
        endVerse.value = verse;
      }
      
      // Reset if selection becomes invalid
      if (startVerse.value > endVerse.value) {
        startVerse.value = 0;
        endVerse.value = 0;
        isSelecting.value = false;
      }
    } else {
      // Extend selection
      if (verse < startVerse.value) {
        startVerse.value = verse;
      } else {
        endVerse.value = verse;
      }
    }
  }

  List<String> getCurrentChapterVerses() {
    if (selectedBook.isEmpty || selectedChapter.value == 0) {
      return [];
    }
    
    try {
      final book = _bibleService.getBookSync(selectedBook.value);
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
    final results = _bibleService.getAllBookNames()
        .where((book) => book.toLowerCase().contains(query.toLowerCase()))
        .map((book) => BibleSearchResult(
          type: BibleSearchResultType.book,
          bookName: book,
          chapter: 0,
          verse: 0,
          text: book,
          relevance: _calculateRelevance(book, query),
        ))
        .toList();
    
    searchResults.assignAll(results);
  }

  Future<void> _searchCurrentChapter(String query) async {
    if (selectedBook.isEmpty || selectedChapter.value == 0) return;
    
    final book = _bibleService.getBookSync(selectedBook.value);
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
    for (final bookName in _bibleService.getAllBookNames()) {
      final book = _bibleService.getBookSync(bookName);
      if (book == null) continue;
      
      // Search through all chapters
      for (final chapterNum in book.chapterData.keys) {
        final chapter = book.getChapter(chapterNum);
        if (chapter == null) continue;
        
        // Search through all verses
        chapter.verses.forEach((verseNum, verseText) {
          if (verseText.toLowerCase().contains(lowerQuery)) {
            results.add(BibleSearchResult(
              type: BibleSearchResultType.verse,
              bookName: bookName,
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

  void navigateToSearchResult(BibleSearchResult result) {
    switch (result.type) {
      case BibleSearchResultType.book:
        selectBook(result.bookName);
        break;
      case BibleSearchResultType.verse:
        selectBook(result.bookName);
        selectChapter(result.chapter);
        // Scroll to specific verse (implementation needed)
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
    _bibleService.clearCache();
  }

  // Debug method
  bool isServiceInitialized() {
    return _bibleService.isInitialized();
  }

  int getBookCount() {
    return _bibleService.getBookCount();
  }

  Map<String, int> getLoadedBooksInfo() {
    return _bibleService.getLoadedBooksInfo();
  }
}
