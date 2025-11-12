import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import '../models/bible.dart';

class BibleService {
  static final BibleService _instance = BibleService._internal();
  factory BibleService() => _instance;
  BibleService._internal();

  final Map<String, BibleBook> _bibleCache = {};
  bool _isInitialized = false;
  bool _isInitializing = false;
  Function(String)? onLoadingMessage; // Callback for loading messages
  Completer<void>? _initializationCompleter;

  Future<void> initialize([Function(String)? loadingCallback]) async {
    // If already initialized, return immediately
    if (_isInitialized) return;

    // If initialization is in progress, wait for it to complete
    if (_isInitializing) {
      await _initializationCompleter?.future;
      return;
    }

    // Start initialization
    _isInitializing = true;
    _initializationCompleter = Completer<void>();
    onLoadingMessage = loadingCallback;

    try {
      await _loadBibleBooksUltraFast();
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Bible service initialization failed: $e');
      }
      // Try fallback initialization
      await _loadBibleBooksFallback();
      _isInitialized = true;
    } finally {
      _isInitializing = false;
      _initializationCompleter?.complete();
    }
  }

  Future<void> _loadBibleBooksUltraFast() async {
    try {
      _onLoadingMessage('Maka lisitra ny boky...');

      // Load the manifest to get all JSON files
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // Filter for Bible books in both Testameta taloha and Testameta vaovao directories
      final List<String> oldTestamentBooks = manifestMap.keys
          .where((key) =>
              key.startsWith('assets/baiboly/Testameta taloha/') &&
              key.endsWith('.json'))
          .toList();

      final List<String> newTestamentBooks = manifestMap.keys
          .where((key) =>
              key.startsWith('assets/baiboly/Testameta vaovao/') &&
              key.endsWith('.json'))
          .toList();

      final totalBooks = oldTestamentBooks.length + newTestamentBooks.length;
      _onLoadingMessage('Maka boky rehetra ($totalBooks boky)...');

      // Combine all books
      final allBooks = [...oldTestamentBooks, ...newTestamentBooks];

      // Load all JSON strings in parallel for maximum performance
      _onLoadingMessage('Maka boky rehetra any amin\'ny cache...');
      final jsonStringFutures = allBooks.map((assetPath) async {
        try {
          final jsonString = await rootBundle.loadString(assetPath);
          return {'path': assetPath, 'data': jsonString};
        } catch (e) {
          if (kDebugMode) {
            print('Failed to load $assetPath: $e');
          }
          return {'path': assetPath, 'data': null};
        }
      }).toList();

      // Wait for all JSON strings to load
      final jsonResults = await Future.wait(jsonStringFutures);

      // Filter out failed loads
      final successfulLoads =
          jsonResults.where((result) => result['data'] != null).toList();

      _onLoadingMessage('Mamaky boky ${successfulLoads.length}...');

      // Parse all JSON data in parallel batches to avoid memory issues
      const batchSize = 10;
      var loadedBooks = 0;

      for (var i = 0; i < successfulLoads.length; i += batchSize) {
        final end = (i + batchSize < successfulLoads.length)
            ? i + batchSize
            : successfulLoads.length;
        final batch = successfulLoads.sublist(i, end);

        // Parse batch in parallel
        final parseFutures = batch.map((result) async {
          final assetPath = result['path'] as String;
          final jsonString = result['data'] as String;

          try {
            final fileName = assetPath.split('/').last;
            final bookFileName =
                fileName.substring(0, fileName.lastIndexOf('.'));
            final isOldTestament = assetPath.contains('Testameta taloha');
            final bookName = isOldTestament
                ? _getOldTestamentBookDisplayName(bookFileName)
                : _getNewTestamentBookDisplayName(bookFileName);

            // Parse JSON data directly without compute for better performance in this case
            final jsonData = json.decode(jsonString) as Map<String, dynamic>;

            // Create BibleBook directly
            final book = BibleBook.fromJson(jsonData, bookName);
            return book;
          } catch (e) {
            if (kDebugMode) {
              print('Failed to parse $assetPath: $e');
            }
            return null;
          }
        }).toList();

        // Wait for parsing to complete
        final parsedBooks = await Future.wait(parseFutures);

        // Add successfully parsed books to cache
        for (final book in parsedBooks) {
          if (book != null) {
            _bibleCache[book.name] = book;
            loadedBooks++;
            if (loadedBooks % 3 == 0) {
              // Update every 3 books to reduce UI updates
              _onLoadingMessage('Voakija: $loadedBooks/$totalBooks boky');
            }
          }
        }

        // Add a small delay to prevent blocking the UI
        await Future.delayed(const Duration(milliseconds: 10));
      }

      _onLoadingMessage('Vita ny famakiana boky ($loadedBooks/$totalBooks)');
    } catch (e) {
      _onLoadingMessage('Nisy olana tamin\'ny famakiana boky: $e');
      rethrow; // Re-throw to trigger fallback
    }
  }

  Future<void> _loadBibleBooksFallback() async {
    try {
      _onLoadingMessage('Maka lisitra ny boky (fallback)...');

      // Fallback method: Try to load specific known books
      final oldTestamentBooks = [
        'amosa',
        'daniela',
        'deoteronomia',
        'eksodosy',
        'estera',
        'ezekiela',
        'ezra',
        'fitomaniana',
        'genesisy',
        'habakoka',
        'hagay',
        'hosea',
        'isaia',
        'jeremia',
        'joba',
        'joela',
        'jona',
        'josoa',
        'lioka',
        'malakia',
        'mika',
        'mpanjaka-faharoa',
        'mpanjaka-voalohany',
        'mpitoriteny',
        'mpitsara',
        'nahoma',
        'nehemia',
        'nomery',
        'obadia',
        'ohabolana',
        'rota',
        'salamo',
        'samoela-faharoa',
        'samoela-voalohany',
        'tantara-faharoa',
        'tantara-voalohany',
        'tononkirani-solomona',
        'zakaria',
        'zefania'
      ];

      final newTestamentBooks = [
        '1-jaona',
        '1-korintianina',
        '1-petera',
        '1-tesalonianina',
        '1-timoty',
        '2-jaona',
        '2-korintianina',
        '2-petera',
        '2-tesalonianina',
        '2-timoty',
        '3-jaona',
        'apokalypsy',
        'asanny-apostoly',
        'efesianina',
        'filemona',
        'filipianina',
        'galatianina',
        'hebreo',
        'jakoba',
        'jaona',
        'joda',
        'kolosianina',
        'levitikosy',
        'marka',
        'matio',
        'romanina',
        'titosy'
      ];

      final totalBooks = oldTestamentBooks.length + newTestamentBooks.length;
      var loadedBooks = 0;

      _onLoadingMessage('Maka boky rehetra ($totalBooks boky)...');

      // Load Old Testament books
      for (final bookFileName in oldTestamentBooks) {
        try {
          final assetPath =
              'assets/baiboly/Testameta taloha/$bookFileName.json';
          final jsonString = await rootBundle.loadString(assetPath);
          final jsonData = json.decode(jsonString) as Map<String, dynamic>;
          final bookName = _getOldTestamentBookDisplayName(bookFileName);
          final book = BibleBook.fromJson(jsonData, bookName);
          _bibleCache[book.name] = book;
          loadedBooks++;
          if (loadedBooks % 3 == 0) {
            _onLoadingMessage('Voakija: $loadedBooks/$totalBooks boky');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to load Old Testament book $bookFileName: $e');
          }
          continue;
        }
      }

      // Load New Testament books
      for (final bookFileName in newTestamentBooks) {
        try {
          final assetPath =
              'assets/baiboly/Testameta vaovao/$bookFileName.json';
          final jsonString = await rootBundle.loadString(assetPath);
          final jsonData = json.decode(jsonString) as Map<String, dynamic>;
          final bookName = _getNewTestamentBookDisplayName(bookFileName);
          final book = BibleBook.fromJson(jsonData, bookName);
          _bibleCache[book.name] = book;
          loadedBooks++;
          if (loadedBooks % 3 == 0) {
            _onLoadingMessage('Voakija: $loadedBooks/$totalBooks boky');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to load New Testament book $bookFileName: $e');
          }
          continue;
        }
      }

      _onLoadingMessage('Vita ny famakiana boky ($loadedBooks/$totalBooks)');
    } catch (e) {
      _onLoadingMessage('Nisy olana tamin\'ny famakiana boky (fallback): $e');
    }
  }

  void _onLoadingMessage(String message) {
    if (onLoadingMessage != null) {
      // Debounce loading messages to reduce UI updates
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
      'asanny-apostoly': 'Asanny Apostoly',
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

  // Get all Bible books
  List<BibleBook> getAllBooks() {
    return _bibleCache.values.toList();
  }

  // Get a specific book by name
  BibleBook? getBookByName(String bookName) {
    return _bibleCache[bookName];
  }

  // Check if service is initialized
  bool get isInitialized => _isInitialized;

  // New methods needed by BibleController
  List<String> getAllBookNames() {
    return _bibleCache.keys.toList()..sort();
  }

  Future<BibleBook?> getBook(String bookName) async {
    return _bibleCache[bookName];
  }

  BibleBook? getBookSync(String bookName) {
    return _bibleCache[bookName];
  }

  List<int> getChaptersForBook(String bookName) {
    final book = _bibleCache[bookName];
    if (book != null) {
      return book.chapterData.keys.toList()..sort();
    }
    return [];
  }

  List<String> searchBooks(String query) {
    if (query.isEmpty) {
      return getAllBookNames();
    }

    return _bibleCache.keys
        .where(
            (bookName) => bookName.toLowerCase().contains(query.toLowerCase()))
        .toList()
      ..sort();
  }

  void clearCache() {
    _bibleCache.clear();
    _isInitialized = false;
    _isInitializing = false;
  }

  int getBookCount() {
    return _bibleCache.length;
  }

  Map<String, int> getLoadedBooksInfo() {
    final Map<String, int> info = {};
    _bibleCache.forEach((name, book) {
      info[name] = book.chapters;
    });
    return info;
  }
}
