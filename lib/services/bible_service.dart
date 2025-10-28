import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/bible.dart';

class BibleService {
  static final BibleService _instance = BibleService._internal();
  factory BibleService() => _instance;
  BibleService._internal();

  final Map<String, BibleBook> _bibleCache = {};
  bool _isInitialized = false;
  Function(String)? onLoadingMessage; // Callback for loading messages

  Future<void> initialize([Function(String)? loadingCallback]) async {
    if (_isInitialized) return;
    
    onLoadingMessage = loadingCallback;
    // Load all Bible books from assets
    await _loadBibleBooks();
    _isInitialized = true;
  }

  Future<void> _loadBibleBooks() async {
    try {
      _onLoadingMessage('Maka lisitra ny boky...');
      
      // Load the manifest to get all JSON files
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // Filter for Bible books in both Testameta taloha and Testameta vaovao directories
      final List<String> oldTestamentBooks = manifestMap.keys
          .where((key) => key.startsWith('assets/baiboly/Testameta taloha/') && key.endsWith('.json'))
          .toList();
          
      final List<String> newTestamentBooks = manifestMap.keys
          .where((key) => key.startsWith('assets/baiboly/Testameta vaovao/') && key.endsWith('.json'))
          .toList();
      
      final totalBooks = oldTestamentBooks.length + newTestamentBooks.length;
      var loadedBooks = 0;
      
      // Load Old Testament books
      for (final assetPath in oldTestamentBooks) {
        try {
          final fileName = assetPath.split('/').last;
          final bookFileName = fileName.substring(0, fileName.lastIndexOf('.'));
          _onLoadingMessage('Maka boky: $bookFileName...');
          
          final jsonString = await rootBundle.loadString(assetPath);
          final jsonData = json.decode(jsonString) as Map<String, dynamic>;
          
          // Extract book name from file path
          final bookName = _getOldTestamentBookDisplayName(bookFileName);
          
          final book = BibleBook.fromJson(jsonData, bookName);
          _bibleCache[book.name] = book;
          loadedBooks++;
          _onLoadingMessage('Voakija: ${book.name} ($loadedBooks/$totalBooks)');
        } catch (e) {
          // Skip books that fail to load
        }
      }
      
      // Load New Testament books
      for (final assetPath in newTestamentBooks) {
        try {
          final fileName = assetPath.split('/').last;
          final bookFileName = fileName.substring(0, fileName.lastIndexOf('.'));
          _onLoadingMessage('Maka boky: $bookFileName...');
          
          final jsonString = await rootBundle.loadString(assetPath);
          final jsonData = json.decode(jsonString) as Map<String, dynamic>;
          
          // Extract book name from file path
          final bookName = _getNewTestamentBookDisplayName(bookFileName);
          
          final book = BibleBook.fromJson(jsonData, bookName);
          _bibleCache[book.name] = book;
          loadedBooks++;
          _onLoadingMessage('Voakija: ${book.name} ($loadedBooks/$totalBooks)');
        } catch (e) {
          // Skip books that fail to load
        }
      }
      
      _onLoadingMessage('Vita ny famakiana boky ($loadedBooks/$totalBooks)');
    } catch (e) {
      _onLoadingMessage('Nisy olana tamin\'ny famakiana boky: $e');
    }
  }

  void _onLoadingMessage(String message) {
    if (onLoadingMessage != null) {
      onLoadingMessage!(message);
    }
  }

  String _getOldTestamentBookDisplayName(String fileName) {
    final bookNames = {
      'amosa': 'Amosa',
      'daniela': 'Daniela',
      'deoteronomia': 'Deoteronomia',
      'eksodosy': 'Eksodosy',
      'estera': 'Estera',
      'ezekiela': 'Ezekiela',
      'ezra': 'Ezra',
      'fitomaniana': 'Fitomaniana',
      'genesisy': 'Genesisy',
      'habakoka': 'Habakoka',
      'hagay': 'Hagay',
      'hosea': 'Hosea',
      'isaia': 'Isaia',
      'jeremia': 'Jeremia',
      'joba': 'Joba',
      'joela': 'Joela',
      'jona': 'Jona',
      'josoa': 'Josoa',
      'lioka': 'Lioka',
      'malakia': 'Malakia',
      'mika': 'Mika',
      'mpanjaka-faharoa': 'Mpanjaka Faharoa',
      'mpanjaka-voalohany': 'Mpanjaka Voalohany',
      'mpitoriteny': 'Mpitoriteny',
      'mpitsara': 'Mpitsara',
      'nahoma': 'Nahoma',
      'nehemia': 'Nehemia',
      'nomery': 'Nomery',
      'obadia': 'Obadia',
      'ohabolana': 'Ohabolana',
      'rota': 'Rota',
      'salamo': 'Salamo',
      'samoela-faharoa': 'Samoela Faharoa',
      'samoela-voalohany': 'Samoela Voalohany',
      'tantara-faharoa': 'Tantara Faharoa',
      'tantara-voalohany': 'Tantara Voalohany',
      'tononkirani-solomona': 'Tononkirani Solomona',
      'zakaria': 'Zakaria',
      'zefania': 'Zefania'
    };

    return bookNames[fileName] ?? fileName;
  }
  
  String _getNewTestamentBookDisplayName(String fileName) {
    final bookNames = {
      '1-jaona': '1 Jaona',
      '1-korintianina': '1 Korintianina',
      '1-petera': '1 Petera',
      '1-tesalonianina': '1 Tesalonianina',
      '1-timoty': '1 Timoty',
      '2-jaona': '2 Jaona',
      '2-korintianina': '2 Korintianina',
      '2-petera': '2 Petera',
      '2-tesalonianina': '2 Tesalonianina',
      '2-timoty': '2 Timoty',
      '3-jaona': '3 Jaona',
      'apokalypsy': 'Apokalypsy',
      'asanny-apostoly': 'Asa. Ap.',
      'efesianina': 'Efesianina',
      'filemona': 'Filemona',
      'filipianina': 'Filipianina',
      'galatianina': 'Galatianina',
      'hebreo': 'Hebreo',
      'jakoba': 'Jakoba',
      'jaona': 'Jaona',
      'joda': 'Joda',
      'kolosianina': 'Kolosianina',
      'levitikosy': 'Levitikosy',
      'marka': 'Marka',
      'matio': 'Matio',
      'romanina': 'Romanina',
      'titosy': 'Titosy'
    };

    return bookNames[fileName] ?? fileName;
  }

  Future<BibleBook?> getBook(String bookName) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Try direct match first
    if (_bibleCache.containsKey(bookName)) {
      return _bibleCache[bookName];
    }

    // Try case-insensitive match
    for (final entry in _bibleCache.entries) {
      if (entry.key.toLowerCase() == bookName.toLowerCase()) {
        return entry.value;
      }
    }

    return null;
  }

  Future<String?> getPassage(String bookName, int chapter, int verse) async {
    final book = await getBook(bookName);
    if (book == null) return null;

    final chapterData = book.getChapter(chapter);
    if (chapterData == null) return null;

    return chapterData.getVerse(verse);
  }

  Future<List<String>?> getPassageRange(String bookName, int chapter, int startVerse, int endVerse) async {
    final book = await getBook(bookName);
    if (book == null) return null;

    final chapterData = book.getChapter(chapter);
    if (chapterData == null) return null;

    return chapterData.getVersesInRange(startVerse, endVerse);
  }

  List<String> searchBooks(String query) {
    final List<String> results = [];
    final lowerQuery = query.toLowerCase();

    for (final bookName in _bibleCache.keys) {
      if (bookName.toLowerCase().contains(lowerQuery)) {
        results.add(bookName);
      }
    }

    // Sort the results alphabetically
    results.sort();
    return results;
  }

  List<int> getChaptersForBook(String bookName) {
    final book = _bibleCache[bookName];
    if (book == null) return [];

    return book.chapterData.keys.toList()..sort();
  }

  List<int> getVersesForChapter(String bookName, int chapter) {
    final book = _bibleCache[bookName];
    if (book == null) return [];

    final chapterData = book.getChapter(chapter);
    if (chapterData == null) return [];

    return chapterData.verses.keys.toList()..sort();
  }

  void clearCache() {
    _bibleCache.clear();
    _isInitialized = false;
  }
  
  // Get all book names
  List<String> getAllBookNames() {
    return _bibleCache.keys.toList()..sort();
  }
  
  // Debug method to check if books are loaded
  bool isInitialized() {
    return _isInitialized;
  }
  
  int getBookCount() {
    return _bibleCache.length;
  }
  
  // Get loaded books info
  Map<String, int> getLoadedBooksInfo() {
    final Map<String, int> info = {};
    _bibleCache.forEach((key, value) {
      info[key] = value.chapters;
    });
    return info;
  }
}