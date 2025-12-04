import 'package:get/get.dart';
import 'package:fihirana/features/bible/domain/entities/bible_search.dart';
import 'package:fihirana/features/bible/domain/usecases/search_books_usecase.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_book_controller.dart';
import 'package:fihirana/core/error/error_handler.dart';

class BibleSearchController extends GetxController {
  final SearchBooksUseCase _searchBooksUseCase;

  BibleSearchController({required SearchBooksUseCase searchBooksUseCase})
      : _searchBooksUseCase = searchBooksUseCase;

  // Search state
  final RxString searchQuery = ''.obs;
  final RxList<BibleSearchResult> searchResults = <BibleSearchResult>[].obs;
  final RxBool isSearching = false.obs;
  final Rx<BibleSearchContext?> searchContext = Rx<BibleSearchContext?>(null);

  // Search history
  final RxList<String> searchHistory = <String>[].obs;

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

    try {
      isSearching.value = true;
      searchContext.value = BibleSearchContext.books;

      final books = _searchBooksUseCase(query);
      final results = books.map((book) => BibleSearchResult(
        type: BibleSearchResultType.book,
        bookName: book.name,
        chapter: 0,
        verse: 0,
        text: book.name,
        relevance: 1.0,
      )).toList();

      searchResults.value = results;

      // Add to search history
      addToSearchHistory(query);
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorSearchingBible'.tr);
    } finally {
      isSearching.value = false;
    }
  }

  void clearSearchResults() {
    searchResults.clear();
    searchContext.value = null;
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
    return searchHistory.where((item) =>
        item.toLowerCase().contains(filter.toLowerCase())).toList();
  }

  void setSearchContext(BibleSearchContext context) {
    searchContext.value = context;
  }

  void navigateToSearchResult(BibleSearchResult result) {
    if (result.type == BibleSearchResultType.book) {
      Get.find<BibleBookController>().selectBook(result.bookName);
    } else if (result.type == BibleSearchResultType.verse) {
      Get.find<BibleBookController>().selectBook(result.bookName);
      Get.find<BibleBookController>().selectChapter(result.chapter);
    }
  }

  bool isVerseSearchHighlighted(int verse) => false; // placeholder
}