import 'dart:math';

import 'package:get/get.dart';
import 'package:fihirana/features/bible/domain/usecases/get_all_books_usecase.dart';
import 'package:fihirana/features/bible/domain/usecases/get_book_usecase.dart';
import 'package:fihirana/core/error/error_handler.dart';
import 'package:fihirana/features/bible/presentation/models/bible_share_data.dart';

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
  final RxInt selectionAnchorVerse = 0.obs;

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
    clearVerseSelection();

    if (bookName.isEmpty) {
      chapterList.clear();
      return;
    }

    loadChaptersForBook(bookName);
  }

  void selectChapter(int chapter) {
    selectedChapter.value = chapter;
    clearVerseSelection();
    loadPassage(selectedBook.value, chapter);
  }

  void selectChapterWithVerseRange(int chapter, int startVerse, int endVerse) {
    selectedChapter.value = chapter;
    clearVerseSelection();
    loadPassage(selectedBook.value, chapter);
    if (startVerse > 0) {
      final lower = min(startVerse, endVerse > 0 ? endVerse : startVerse);
      final upper = max(startVerse, endVerse > 0 ? endVerse : startVerse);
      selectedVerses
        ..clear()
        ..addAll(List<int>.generate(upper - lower + 1, (index) => lower + index));
      selectedVerses.refresh();
      isSelecting.value = true;
    }
  }

  int getVerseCount(String bookName, int chapterNumber) {
    final book = _getBookUseCase(bookName);
    if (book != null && book.chapterData.containsKey(chapterNumber)) {
      return book.chapterData[chapterNumber]?.verses.length ?? 0;
    }
    return 0;
  }

  void toggleVerseSelection(int verseNumber) {
    if (verseNumber <= 0) {
      return;
    }

    if (selectedVerses.isEmpty || selectionAnchorVerse.value == 0) {
      _startSelectionAt(verseNumber);
      return;
    }

    _selectContinuousRangeTo(verseNumber);
  }

  void clearVerseSelection() {
    selectedVerses.clear();
    isSelecting.value = false;
    selectionAnchorVerse.value = 0;
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
    final verseLabel = _formatVerseLabel(sortedVerses);

    return '$book $chapter:$verseLabel';
  }

  BibleShareData? buildSelectedShareData() {
    if (selectedBook.value.isEmpty ||
        selectedChapter.value == 0 ||
        selectedVerses.isEmpty) {
      return null;
    }

    final verseLines = getSelectedVerseLines();
    if (verseLines.isEmpty) {
      return null;
    }

    return BibleShareData(
      bookName: selectedBook.value,
      chapter: selectedChapter.value,
      verses: verseLines,
    );
  }

  List<BibleShareVerseLine> getSelectedVerseLines() {
    final book = _getBookUseCase(selectedBook.value);
    final chapterData = book?.chapterData[selectedChapter.value];
    if (chapterData == null || selectedVerses.isEmpty) {
      return <BibleShareVerseLine>[];
    }

    final sortedVerses = selectedVerses.toList()..sort();

    return sortedVerses
        .map((verseNumber) => BibleShareVerseLine(
              number: verseNumber,
              text: chapterData.verses[verseNumber] ?? '',
            ))
        .toList(growable: false);
  }

  void _startSelectionAt(int verseNumber) {
    selectionAnchorVerse.value = verseNumber;
    isSelecting.value = true;
    _selectContinuousRangeTo(verseNumber);
  }

  void _selectContinuousRangeTo(int verseNumber) {
    final anchorVerse = selectionAnchorVerse.value;
    final lower = min(anchorVerse, verseNumber);
    final upper = max(anchorVerse, verseNumber);

    selectedVerses
      ..clear()
      ..addAll(List<int>.generate(upper - lower + 1, (index) => lower + index));
    selectedVerses.refresh();
    isSelecting.value = true;
  }

  String _formatVerseLabel(List<int> sortedVerses) {
    if (sortedVerses.length == 1) {
      return sortedVerses.first.toString();
    }

    var isContinuous = true;
    for (var index = 1; index < sortedVerses.length; index++) {
      if (sortedVerses[index] != sortedVerses[index - 1] + 1) {
        isContinuous = false;
        break;
      }
    }

    if (isContinuous) {
      return '${sortedVerses.first}-${sortedVerses.last}';
    }

    return sortedVerses.join(',');
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
