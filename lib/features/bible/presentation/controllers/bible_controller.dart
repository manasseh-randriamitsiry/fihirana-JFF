import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/features/bible/domain/usecases/initialize_bible_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/get_all_books_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/get_book_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/search_books_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/search_verses_usecase.dart';
import 'package:fihirana/features/bible/domain/entities/bible_highlight.dart';
import 'package:fihirana/features/bible/domain/entities/bible_search.dart';
import 'package:fihirana/features/bible/data/services/bible_highlight_service.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_book_controller.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_highlight_controller.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_search_controller.dart';
import 'package:fihirana/features/bible/presentation/models/bible_share_data.dart';
import 'package:fihirana/core/error/error_handler.dart';

class BibleController extends GetxController {
  final InitializeBibleUseCase _initializeBibleUseCase;

  // Sub-controllers for different concerns
  late final BibleBookController bookController;
  late final BibleHighlightController highlightController;
  late final BibleSearchController searchController;

  BibleController({
    required InitializeBibleUseCase initializeBibleUseCase,
    required GetAllBooksUseCase getAllBooksUseCase,
    required GetBookUseCase getBookUseCase,
    required SearchBooksUseCase searchBooksUseCase,
    required SearchVersesUseCase searchVersesUseCase,
    required BibleHighlightService highlightService,
  }) : _initializeBibleUseCase = initializeBibleUseCase {
    // Initialize sub-controllers
    bookController = Get.put(BibleBookController(
      getAllBooksUseCase: getAllBooksUseCase,
      getBookUseCase: getBookUseCase,
    ));

    highlightController = Get.put(BibleHighlightController(
      highlightService: highlightService,
    ));

    searchController = Get.put(BibleSearchController(
      searchBooksUseCase: searchBooksUseCase,
      searchVersesUseCase: searchVersesUseCase,
    ));
  }

  // Delegate properties for backward compatibility
  String get selectedBook => bookController.selectedBook.value;
  set selectedBook(String value) => bookController.selectedBook.value = value;

  int get selectedChapter => bookController.selectedChapter.value;
  set selectedChapter(int value) =>
      bookController.selectedChapter.value = value;

  String get passageText => bookController.passageText.value;
  bool get isLoading => bookController.isLoading.value;
  String get loadingMessage => bookController.loadingMessage.value;
  List<String> get bookList => bookController.bookList;
  List<int> get chapterList => bookController.chapterList;
  Set<int> get selectedVerses => bookController.selectedVerses;
  bool get isSelecting => bookController.isSelecting.value;
  int get selectedVerseCount => bookController.selectedVerses.length;

  RxList<BibleHighlight> get highlights => highlightController.highlights;
  RxList<BibleHighlight> get publicHighlights =>
      highlightController.publicHighlights;

  RxString get searchQuery => searchController.searchQuery;

  RxList<BibleSearchResult> get searchResults => searchController.searchResults;
  RxBool get isSearching => searchController.isSearching;

  // Additional properties for backward compatibility
  var filteredBooks = <String>[].obs;
  var booksByTestament = <String, List<String>>{}.obs;
  var oldTestamentBooks = <String>[].obs;
  var newTestamentBooks = <String>[].obs;
  var highlightedVerse = 0.obs;

  @override
  void onInit() {
    super.onInit();

    // Every entry point uses the same book/chapter/verse transition so the
    // reader state, remote highlights, and indexed scroll stay synchronized.
    searchController.onNavigateToVerse = navigateToVerse;

    _initializeBibleService();
    _loadLastViewedPassage();
    // Populate books by testament
    if (bookList.isNotEmpty) {
      booksByTestament.value = {
        'Testamenta Taloha': bookList.sublist(0, 39),
        'Testamenta Vaovao': bookList.sublist(39),
      };
      oldTestamentBooks.value = bookList.sublist(0, 39);
      newTestamentBooks.value = bookList.sublist(39);
    }
  }

  Future<void> _initializeBibleService() async {
    try {
      await _initializeBibleUseCase((message) {
        // Update loading message if needed
      });
      // Sub-controllers handle their own initialization
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorInitializingBible'.tr);
    }
  }

  Future<void> _loadLastViewedPassage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastBook = prefs.getString('last_bible_book');

      // Only load the book, not the chapter
      // This shows chapter selection instead of auto-opening to verses
      if (lastBook != null && lastBook.isNotEmpty) {
        bookController.selectBook(lastBook);
        // Don't auto-select chapter - let user choose from chapter grid
      }
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorLoadingLastPassage'.tr);
    }
  }

  // Delegate methods to sub-controllers
  void selectBook(String bookName) {
    highlightedVerse.value = 0;
    bookController.selectBook(bookName);
    highlightController.clearChapterHighlights();
  }

  void selectChapter(int chapter) {
    highlightedVerse.value = 0;
    bookController.selectChapter(chapter);
    highlightController.loadHighlights(selectedBook, chapter);
  }

  void selectChapterWithVerseRange(int chapter, int startVerse, int endVerse) {
    highlightedVerse.value = 0;
    bookController.selectChapterWithVerseRange(chapter, startVerse, endVerse);
    highlightController.loadHighlights(selectedBook, chapter);

    // The reader listens to this value and scrolls to the first verse of the
    // requested range once the chapter is rendered.
    if (startVerse > 0) {
      highlightedVerse.value = startVerse;
    }
  }

  /// Opens a specific verse without leaving stale book, chapter, or Firestore
  /// highlight state behind. Used by search results and saved highlights.
  void navigateToVerse(String bookName, int chapter, int verse) {
    if (bookName.isEmpty || chapter <= 0) {
      return;
    }

    selectBook(bookName);
    selectChapter(chapter);
    if (verse > 0) {
      highlightedVerse.value = verse;
    }
  }

  int getVerseCountForChapter(String bookName, int chapterNumber) =>
      bookController.getVerseCount(bookName, chapterNumber);

  void toggleVerseSelection(int verseNumber) {
    bookController.toggleVerseSelection(verseNumber);
  }

  void clearVerseSelection() {
    bookController.clearVerseSelection();
  }

  void startVerseSelection() {
    bookController.startVerseSelection();
  }

  String getSelectedVersesText() {
    return bookController.getSelectedVersesText();
  }

  BibleShareData? buildSelectedShareData() {
    return bookController.buildSelectedShareData();
  }

  void addHighlight(int verse, String color) {
    highlightController.addHighlight(
        selectedBook, selectedChapter, verse, color);
  }

  void removeHighlight(String highlightId) {
    highlightController.removeHighlight(highlightId);
  }

  void updateHighlight(dynamic highlight) {
    highlightController.updateHighlight(highlight);
  }

  Future<bool> canEditHighlight(dynamic highlight) async {
    return await highlightController.canEditHighlight(highlight);
  }

  dynamic getHighlightForVerse(int verseNumber) {
    return highlightController.getHighlightForVerse(verseNumber);
  }

  void updateSearchQuery(String query) {
    searchController.updateSearchQuery(query);
  }

  Future<void> performSearch() async {
    await searchController.performSearch();
  }

  void clearSearchResults() {
    searchController.clearSearchResults();
  }

  void addToSearchHistory(String query) {
    searchController.addToSearchHistory(query);
  }

  void removeFromSearchHistory(String query) {
    searchController.removeFromSearchHistory(query);
  }

  void clearSearchHistory() {
    searchController.clearSearchHistory();
  }

  List<String> getFilteredSearchHistory(String filter) {
    return searchController.getFilteredSearchHistory(filter);
  }

  // Statistics method for backward compatibility
  Map<String, dynamic> getBibleStatistics() {
    return {
      'totalBooks': bookList.length,
      'selectedBook': selectedBook,
      'selectedChapter': selectedChapter,
      'hasHighlights': highlights.isNotEmpty,
      'searchHistoryCount': searchController.searchHistory.length,
    };
  }

  int getChapterCountForBook(String bookName) =>
      bookController.getChapterCountForBook(bookName);

  bool isVerseSelected(int verse) => bookController.isVerseSelected(verse);

  bool isVerseHighlighted(int verse) =>
      highlightController.isVerseHighlighted(verse);

  bool isVerseSearchHighlighted(int verse) =>
      searchController.isVerseSearchHighlighted(verse);

  void setSearchContext(BibleSearchContext context) =>
      searchController.setSearchContext(context);

  void navigateToSearchResult(BibleSearchResult result) =>
      searchController.navigateToSearchResult(result);

  void clearSelection() => bookController.clearVerseSelection();

  void saveHighlight() {
    for (final verse in selectedVerses) {
      highlightController.addHighlight(
          selectedBook, selectedChapter, verse, 'yellow');
    }
    clearSelection();
  }

  List<String> getCurrentChapterVerses() =>
      bookController.getCurrentChapterVerses();
}
