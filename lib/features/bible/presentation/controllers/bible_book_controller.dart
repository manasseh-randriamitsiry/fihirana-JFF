import 'package:get/get.dart';
import 'package:fihirana/features/bible/domain/usecases/get_all_books_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/get_book_usecase.dart';
import 'package:fihirana/core/error/error_handler.dart';

class BibleBookController extends GetxController {
  final GetAllBooksUseCase _getAllBooksUseCase;
  final GetBookUseCase _getBookUseCase;

  BibleBookController({
    required GetAllBooksUseCase getAllBooksUseCase,
    required GetBookUseCase getBookUseCase,
  })  : _getAllBooksUseCase = getAllBooksUseCase,
        _getBookUseCase = getBookUseCase;

  // Book and chapter selection
  final RxString selectedBook = ''.obs;
  final RxInt selectedChapter = 0.obs;
  final RxString passageText = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString loadingMessage = 'Maka boky...'.obs;
  final RxList<String> bookList = <String>[].obs;
  final RxList<int> chapterList = <int>[].obs;

  // Verse selection
  final RxSet<int> selectedVerses = <int>{}.obs;
  final RxBool isSelecting = false.obs;

  // Passage cache
  final Map<String, String> _passageCache = {};
  static const int _maxCacheSize = 50;

  @override
  void onInit() {
    super.onInit();
    loadBooks();
  }

  void loadBooks() {
    try {
      isLoading.value = true;
      loadingMessage.value = 'Maka boky...';

      final books = _getAllBooksUseCase();
      bookList.value = books.map((book) => book.name).toList();

      // Don't auto-select first book - show book list instead
      // This allows users to choose which book to read
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorLoadingBooks'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void loadChaptersForBook(String bookName) {
    try {
      final book = _getBookUseCase(bookName);
      if (book != null) {
        chapterList.value = List.generate(book.chapters, (index) => index + 1);

        // Don't auto-select first chapter - show chapter grid instead
        // selectedChapter stays 0, which triggers chapter selection view
      }
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorLoadingChapters'.tr);
    }
  }

  void loadPassage(String bookName, int chapter) {
    final cacheKey = '$bookName:$chapter';

    if (_passageCache.containsKey(cacheKey)) {
      passageText.value = _passageCache[cacheKey]!;
      return;
    }

    try {
      isLoading.value = true;
      loadingMessage.value = 'Maka andininy...';

      final book = _getBookUseCase(bookName);
      if (book != null && book.chapterData.containsKey(chapter)) {
        final chapterData = book.chapterData[chapter]!;

        final passage = chapterData.verses.entries
            .map((entry) => '${entry.key}. ${entry.value}')
            .join('\n\n');

        passageText.value = passage;

        // Cache the passage
        _passageCache[cacheKey] = passage;
        _manageCacheSize();
      }
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorLoadingPassage'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void selectBook(String bookName) {
    selectedBook.value = bookName;
    selectedChapter.value = 0;
    passageText.value = '';
    selectedVerses.clear();
    loadChaptersForBook(bookName);
  }

  void selectChapter(int chapter) {
    selectedChapter.value = chapter;
    selectedVerses.clear();
    loadPassage(selectedBook.value, chapter);
  }

  void toggleVerseSelection(int verseNumber) {
    if (selectedVerses.contains(verseNumber)) {
      selectedVerses.remove(verseNumber);
      // If no verses left, stop selecting mode
      if (selectedVerses.isEmpty) {
        isSelecting.value = false;
      }
    } else {
      selectedVerses.add(verseNumber);
      // Enable selecting mode when first verse is added
      if (!isSelecting.value) {
        isSelecting.value = true;
      }
    }
  }

  void clearVerseSelection() {
    selectedVerses.clear();
    isSelecting.value = false;
  }

  void startVerseSelection() {
    isSelecting.value = true;
  }

  void cancelVerseSelection() {
    clearVerseSelection();
  }

  String getSelectedVersesText() {
    if (selectedVerses.isEmpty) return '';

    final sortedVerses = selectedVerses.toList()..sort();
    final book = selectedBook.value;
    final chapter = selectedChapter.value;

    return '$book $chapter:${sortedVerses.join(',')}';
  }

  void _manageCacheSize() {
    if (_passageCache.length > _maxCacheSize) {
      final keysToRemove =
          _passageCache.keys.take(_passageCache.length - _maxCacheSize);
      for (final key in keysToRemove) {
        _passageCache.remove(key);
      }
    }
  }

  int getChapterCountForBook(String bookName) {
    final book = _getBookUseCase(bookName);
    return book?.chapters ?? 0;
  }

  bool isVerseSelected(int verse) => selectedVerses.contains(verse);

  dynamic getBook(String bookName) => _getBookUseCase(bookName);

  List<String> getCurrentChapterVerses() {
    final book = _getBookUseCase(selectedBook.value);
    if (book != null && book.chapterData.containsKey(selectedChapter.value)) {
      final chapterData = book.chapterData[selectedChapter.value]!;
      return chapterData.verses.values.toList();
    }
    return [];
  }
}
