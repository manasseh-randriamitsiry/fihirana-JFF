import 'dart:async';

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

  // Callback to set highlighted verse (set by parent controller)
  Function(int)? onSetHighlightedVerse;

  // ── Debounce / cancellation ──────────────────────────────────────────────
  Timer? _debounceTimer;

  /// Token incremented each time a new search is requested. Running searches
  /// compare against this token; if it has changed, they discard their result.
  int _searchToken = 0;

  /// Debounce delay for expensive (allBible / currentChapter) searches.
  static const _kDebounceMs = 500;

  @override
  void onInit() {
    super.onInit();
    loadSearchHistory();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  // ── Public helpers ────────────────────────────────────────────────────────

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      _debounceTimer?.cancel();
      searchResults.clear();
      isSearching.value = false;
      // NOTE: intentionally do NOT null the context here so that switching
      // context → clearing text → typing again still uses the correct context.
    }
  }

  /// Trigger a debounced search.
  ///
  /// * For [BibleSearchContext.books] (in-memory): executes immediately.
  /// * For [BibleSearchContext.allBible] / [BibleSearchContext.currentChapter]
  ///   (loads JSON files): waits [_kDebounceMs] ms after the last call before
  ///   actually searching, cancelling any in-flight search.
  Future<void> performSearch() async {
    final query = searchQuery.value.trim();
    if (query.isEmpty) {
      _debounceTimer?.cancel();
      searchResults.clear();
      isSearching.value = false;
      return;
    }

    final ctx = searchContext.value;

    // Book searches are instant (in-memory), no debounce needed.
    if (ctx == BibleSearchContext.books) {
      _debounceTimer?.cancel();
      await _doSearch(query, ctx);
      return;
    }

    // Verse searches are expensive – debounce them.
    _debounceTimer?.cancel();
    isSearching.value = true; // show spinner immediately

    _debounceTimer = Timer(
      const Duration(milliseconds: _kDebounceMs),
      () => _doSearch(query, ctx),
    );
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _doSearch(String query, BibleSearchContext? ctx) async {
    // Each search gets a unique token; stale completions are discarded.
    final token = ++_searchToken;

    try {
      isSearching.value = true;

      List<BibleSearchResult> results = [];

      if (ctx == BibleSearchContext.books) {
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
      } else if (ctx == BibleSearchContext.allBible) {
        final verses = await _searchVersesUseCase(query);
        if (token != _searchToken) return; // superseded
        results = _convertVerseSearchResults(verses);
      } else if (ctx == BibleSearchContext.currentChapter) {
        final bookController = Get.find<BibleBookController>();
        final currentBook = bookController.selectedBook.value;
        final currentChapter = bookController.selectedChapter.value;

        if (currentBook.isNotEmpty && currentChapter > 0) {
          final allVerses = await _searchVersesUseCase(query);
          if (token != _searchToken) return; // superseded
          final filtered = allVerses
              .where((v) =>
                  v.bookName == currentBook && v.chapter == currentChapter)
              .toList();
          results = _convertVerseSearchResults(filtered);
        }
      } else {
        // Context not yet set – default to book search.
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
      }

      if (token != _searchToken) return; // superseded while awaiting

      searchResults.value = results;
      addToSearchHistory(query);
    } catch (e) {
      if (token == _searchToken) {
        ErrorHandler.handleError(e, message: 'errorSearchingBible'.tr);
      }
    } finally {
      if (token == _searchToken) {
        isSearching.value = false;
      }
    }
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

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
    _debounceTimer?.cancel();
    searchResults.clear();
    isSearching.value = false;
    // NOTE: do NOT null searchContext here – it preserves the user's chosen
    // search scope when they clear the text and start typing again.
  }

  void addToSearchHistory(String query) {
    if (!searchHistory.contains(query)) {
      searchHistory.insert(0, query);
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
    searchHistory.value = [];
  }

  void saveSearchHistory() {
    // TODO: persist to SharedPreferences
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

      if (onSetHighlightedVerse != null) {
        Future.delayed(const Duration(milliseconds: 400), () {
          onSetHighlightedVerse!(result.verse);
        });
      }
    }
  }

  bool isVerseSearchHighlighted(int verse) => false;
}