import 'package:get/get.dart';
import '../models/bible.dart';
import '../services/bible_service.dart';

class BibleController extends GetxController {
  final BibleService _bibleService = BibleService();
  
  var selectedBook = ''.obs;
  var selectedChapter = 0.obs;
  var passageText = ''.obs;
  var isLoading = false.obs;
  var loadingMessage = 'Maka boky...'.obs;
  var bookList = <String>[].obs;
  var chapterList = <int>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    _initializeBibleService();
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
  
  Future<void> loadPassage() async {
    if (selectedBook.isEmpty || selectedChapter.value == 0) return;
    
    isLoading.value = true;
    loadingMessage.value = 'Maka andininy any amin\'i ${selectedBook.value} ${selectedChapter.value}...';
    try {
      final book = await _bibleService.getBook(selectedBook.value);
      final chapter = book?.getChapter(selectedChapter.value);
      
      if (chapter != null) {
        // Format the chapter text with verse numbers
        final StringBuffer formattedText = StringBuffer();
        chapter.verses.forEach((verseNum, verseText) {
          formattedText.write('$verseNum. $verseText\n\n');
        });
        
        passageText.value = formattedText.toString();
      } else {
        print('Chapter not found: ${selectedChapter.value} in book: ${selectedBook.value}');
      }
    } catch (e) {
      print('Error loading passage: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  void selectBook(String bookName) {
    print('Selecting book: $bookName');
    selectedBook.value = bookName;
    selectedChapter.value = 0;
    passageText.value = '';
    
    // Get chapters for the selected book
    chapterList.value = _bibleService.getChaptersForBook(bookName);
    print('Chapter list for $bookName: ${chapterList.value}');
  }
  
  void selectChapter(int chapter) {
    print('Selecting chapter: $chapter');
    selectedChapter.value = chapter;
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