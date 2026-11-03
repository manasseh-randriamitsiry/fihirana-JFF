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
  String _lastExecutedPassage = '';

  Set<int> _highlightedVerses = {};
  String? _highlightCacheKey;

  // Delegates verse navigation to the parent controller, which owns the
  // active chapter, highlight streams, and reader scroll state.
  void Function(String bookName, int chapter, int verse)? onNavigateToVerse;

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

  /// The scope a search actually runs in. The reader can open the dialog before
  /// a chapter is on screen, and a scope that silently finds nothing reads as a
  /// broken search, so both cases mean the whole Bible.
  BibleSearchContext get activeSearchContext => _resolve(searchContext.value);

  /// Whether the reader sits on a chapter, which is the only moment searching
  /// that chapter can mean anything.
  bool get hasOpenChapter => _openPassage.isNotEmpty;

  BibleSearchContext _resolve(BibleSearchContext? context) {
    final hasOpenChapter = _openPassage.isNotEmpty;
    if (context == null) {
      // Nothing picked yet: the chapter the reader is on, since that is the
      // passage in front of them.
      return hasOpenChapter
          ? BibleSearchContext.currentChapter
          : BibleSearchContext.allBible;
    }
    if (context == BibleSearchContext.currentChapter && !hasOpenChapter) {
      return BibleSearchContext.allBible;
    }
    return context;
  }

  /// The chapter the reader sits on as '<book> <chapter>', or '' when no
  /// chapter is open. A chapter change moves the results of a chapter search,
  /// so it is part of what says whether a search already ran.
  String get _openPassage {
    final bookController = Get.find<BibleBookController>();
    final book = bookController.selectedBook.value;
    final chapter = bookController.selectedChapter.value;
    return book.isEmpty || chapter <= 0 ? '' : '$book $chapter';
  }

  Future<void> performSearch() async {
    final query = searchQuery.value.trim();
    if (query.isEmpty) {
      clearSearchResults();
      return;
    }
    final context = activeSearchContext;
    final passage =
        context == BibleSearchContext.currentChapter ? _openPassage : '';

    if (query == _lastExecutedQuery &&
        context == _lastExecutedContext &&
        passage == _lastExecutedPassage) {
      return;
    }

    try {
      isSearching.value = true;

      List<BibleSearchResult> results;

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
      } else {
        final verses = _searchVersesUseCase(query);
        results = context == BibleSearchContext.currentChapter
            ? _convertVerseSearchResults(_inOpenChapter(verses, passage))
            : _convertVerseSearchResults(verses);
      }

      searchResults.value = results;
      _lastExecutedQuery = query;
      _lastExecutedContext = context;
      _lastExecutedPassage = passage;

      // Add to search history
      addToSearchHistory(query);
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorSearchingBible'.tr);
    } finally {
      isSearching.value = false;
    }
  }

  List<VerseSearchResult> _inOpenChapter(
      List<VerseSearchResult> verses, String passage) {
    return verses
        .where((verse) => '${verse.bookName} ${verse.chapter}' == passage)
        .toList();
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
    _lastExecutedQuery = '';
    _lastExecutedContext = null;
    _lastExecutedPassage = '';
    _highlightCacheKey = null;
    _highlightedVerses = {};
  }

  /// Empty the field, its results and the picked scope. The controller lives
  /// with the reader, not with the dialog, so a dialog that reopens without
  /// this shows the previous search's hits under an empty field - and stays on
  /// a scope chosen during the search that has since been closed.
  void resetSearch() {
    searchQuery.value = '';
    searchContext.value = null;
    clearSearchResults();
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
      final navigateToVerse = onNavigateToVerse;
      if (navigateToVerse != null) {
        navigateToVerse(result.bookName, result.chapter, result.verse);
      } else {
        // Retain a safe fallback for isolated controller tests.
        bookController.selectBook(result.bookName);
        bookController.selectChapter(result.chapter);
      }
    }
  }

  bool isVerseSearchHighlighted(int verse) {
    if (searchResults.isEmpty) return false;

    final bookController = Get.find<BibleBookController>();
    // Rebuilt only when the visible chapter or the query changes: the reader
    // asks per rendered verse, and a result list can run into the thousands.
    final chapterKey =
        '${bookController.selectedBook.value} ${bookController.selectedChapter.value}';
    final cacheKey = '${searchQuery.value.trim()}|$chapterKey';
    if (_highlightCacheKey != cacheKey) {
      _highlightCacheKey = cacheKey;
      _highlightedVerses = {
        for (final result in searchResults)
          if (result.type == BibleSearchResultType.verse &&
              '${result.bookName} ${result.chapter}' == chapterKey)
            result.verse,
      };
    }

    return _highlightedVerses.contains(verse);
  }
}
