import 'package:get/get.dart';
import 'package:fihirana/features/bible/domain/entities/bible_search.dart';
import 'package:fihirana/features/bible/domain/usecases/search_books_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/search_verses_usecase.dart';
import 'package:fihirana/features/bible/domain/repositories/bible_repository.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_book_controller.dart';
import 'package:fihirana/core/error/error_handler.dart';

class BibleSearchController extends GetxController {
  final SearchBooksUseCase _searchBooksUseCase;
  final SearchVersesUseCase _searchVersesUseCase;

  BibleSearchController({
    required SearchBooksUseCase searchBooksUseCase,
    required SearchVersesUseCase searchVersesUseCase,
  })  : _searchBooksUseCase = searchBooksUseCase,
        _searchVersesUseCase = searchVersesUseCase;

  // Search state
  final RxString searchQuery = ''.obs;
  final RxList<BibleSearchResult> searchResults = <BibleSearchResult>[].obs;
  final RxBool isSearching = false.obs;
  final Rx<BibleSearchContext?> searchContext = Rx<BibleSearchContext?>(null);

  // Search history
  final RxList<String> searchHistory = <String>[].obs;
  String _lastExecutedQuery = '';
  BibleSearchContext? _lastExecutedContext;

  // Callback to set highlighted verse (set by parent controller)
  Function(int)? onSetHighlightedVerse;

  @override
  void onInit() {
    super.onInit();
    loadSearchHistory();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      clearSearchResults();
    }
  }

  Future<void> performSearch() async {
    final query = searchQuery.value.trim();
    if (query.isEmpty) return;
    final context = searchContext.value;

    if (query == _lastExecutedQuery && context == _lastExecutedContext) {
      return;
    }

    try {
      isSearching.value = true;

      List<BibleSearchResult> results = [];

      // Search based on current context
      if (context == BibleSearchContext.books) {
        // Search for books
        final books = _searchBooksUseCase(query);
        results = books
            .map((book) => BibleSearchResult(
                  type: BibleSearchResultType.book,
                  bookName: book.name,
                  chapter: 0,
                  verse: 0,
                  text: book.name,
                  relevance: 1.0,
                ))
            .toList();
      } else if (context == BibleSearchContext.allBible) {
        // Search all verses
        final verses = _searchVersesUseCase(query);
        results = _convertVerseSearchResults(verses);
      } else if (context == BibleSearchContext.currentChapter) {
        // Search only in current chapter
        final bookController = Get.find<BibleBookController>();
        final currentBook = bookController.selectedBook.value;
        final currentChapter = bookController.selectedChapter.value;

        if (currentBook.isNotEmpty && currentChapter > 0) {
          final allVerses = _searchVersesUseCase(query);
          // Filter to only current chapter
          final filteredVerses = allVerses
              .where((verse) =>
                  verse.bookName == currentBook &&
                  verse.chapter == currentChapter)
              .toList();
          results = _convertVerseSearchResults(filteredVerses);
        }
      }

      searchResults.value = results;
      _lastExecutedQuery = query;
      _lastExecutedContext = context;

      // Add to search history
      addToSearchHistory(query);
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorSearchingBible'.tr);
    } finally {
      isSearching.value = false;
    }
  }

  /// Convert VerseSearchResult to BibleSearchResult
  List<BibleSearchResult> _convertVerseSearchResults(
      List<VerseSearchResult> verses) {
    return verses
        .map((verse) => BibleSearchResult(
              type: BibleSearchResultType.verse,
              bookName: verse.bookName,
              chapter: verse.chapter,
              verse: verse.verse,
              text: verse.text,
              relevance: 1.0,
            ))
        .toList();
  }

  void clearSearchResults() {
    searchResults.clear();
    searchContext.value = null;
    _lastExecutedQuery = '';
    _lastExecutedContext = null;
  }

  void addToSearchHistory(String query) {
    if (!searchHistory.contains(query)) {
      searchHistory.insert(0, query);
      // Keep only last 10 searches
      if (searchHistory.length > 10) {
        searchHistory.removeRange(10, searchHistory.length);
      }
      saveSearchHistory();
    }
  }

  void removeFromSearchHistory(String query) {
    searchHistory.remove(query);
    saveSearchHistory();
  }

  void clearSearchHistory() {
    searchHistory.clear();
    saveSearchHistory();
  }

  void loadSearchHistory() {
    // Load from shared preferences
    // For now, initialize empty
    searchHistory.value = [];
  }

  void saveSearchHistory() {
    // Save to shared preferences
    // Implementation would go here
  }

  List<String> getFilteredSearchHistory(String filter) {
    if (filter.isEmpty) return searchHistory;
    return searchHistory
        .where((item) => item.toLowerCase().contains(filter.toLowerCase()))
        .toList();
  }

  void setSearchContext(BibleSearchContext context) {
    searchContext.value = context;
  }

  void navigateToSearchResult(BibleSearchResult result) {
    final bookController = Get.find<BibleBookController>();

    if (result.type == BibleSearchResultType.book) {
      bookController.selectBook(result.bookName);
    } else if (result.type == BibleSearchResultType.verse) {
      bookController.selectBook(result.bookName);
      bookController.selectChapter(result.chapter);

      // Set the highlighted verse using the callback
      if (onSetHighlightedVerse != null) {
        // Increase delay to ensure chapter loads first
        Future.delayed(const Duration(milliseconds: 400), () {
          onSetHighlightedVerse!(result.verse);
        });
      }
    }
  }

  bool isVerseSearchHighlighted(int verse) => false; // placeholder
}
