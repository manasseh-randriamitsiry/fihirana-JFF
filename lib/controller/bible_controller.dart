import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible_highlight.dart';
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
      print('Error initializing Bible service: $e');
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
      print('Error loading last viewed passage: $e');
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
        print(
            'Chapter not found: ${selectedChapter.value} in book: ${selectedBook.value}');
      }
    } catch (e) {
      print('Error loading passage: $e');
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
      print('Error saving last viewed passage: $e');
    }
  }

  void selectBook(String bookName) {
    print('Selecting book: $bookName');
    selectedBook.value = bookName;
    selectedChapter.value = 0;
    passageText.value = '';

    // Reset verse selection
    startVerse.value = 0;
    endVerse.value = 0;
    isSelecting.value = false;

    // Get chapters for the selected book
    chapterList.value = _bibleService.getChaptersForBook(bookName);
    print('Chapter list for $bookName: ${chapterList.value}');
  }

  void selectChapter(int chapter) {
    print('Selecting chapter: $chapter');
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
