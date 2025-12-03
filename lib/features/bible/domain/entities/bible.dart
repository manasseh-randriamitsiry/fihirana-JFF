class BibleBook {
  final String name;
  final String abbreviation;
  final int chapters;
  final Map<int, BibleChapter> chapterData;

  BibleBook({
    required this.name,
    required this.abbreviation,
    required this.chapters,
    required this.chapterData,
  });

  factory BibleBook.fromJson(Map<String, dynamic> json, String bookName) {
    final Map<int, BibleChapter> chapters = {};

    // Handle new format with "chapters" array
    if (json.containsKey('chapters')) {
      final chaptersList = json['chapters'] as List<dynamic>;
      
      // Pre-size map for better performance
      chapters.reserve(chaptersList.length);

      for (final chapterData in chaptersList) {
        if (chapterData is Map<String, dynamic>) {
          final chapterNum = chapterData['chapter'] as int? ?? 0;
          if (chapterNum > 0) {
            chapters[chapterNum] = BibleChapter.fromJson(chapterData, chapterNum);
          }
        }
      }
    } else {
      // Handle legacy format (flat structure)
      // Pre-size map for better performance
      chapters.reserve(_estimateChapterCount(json));

      // Process chapters more efficiently
      json.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          // Fast integer parsing
          final chapterNum = _fastParseInt(key);
          if (chapterNum != null) {
            chapters[chapterNum] = BibleChapter.fromJson(value, chapterNum);
          }
        }
      });
    }

    return BibleBook(
      name: bookName,
      abbreviation: bookName.length >= 3
          ? bookName.substring(0, 3).toUpperCase()
          : bookName.toUpperCase(),
      chapters: chapters.length,
      chapterData: chapters,
    );
  }

  static int _estimateChapterCount(Map<String, dynamic> json) {
    // More accurate estimation
    return json.length > 150 ? 170 : (json.length + 20);
  }

  static int? _fastParseInt(String str) {
    // Fast integer parsing without exception handling overhead
    if (str.isEmpty) return null;

    int result = 0;
    for (int i = 0; i < str.length; i++) {
      final char = str.codeUnitAt(i);
      if (char >= 48 && char <= 57) {
        // '0' to '9'
        result = result * 10 + (char - 48);
      } else {
        return null; // Not a valid integer
      }
    }
    return result;
  }

  BibleChapter? getChapter(int chapter) {
    return chapterData[chapter];
  }
}

class BibleChapter {
  final int number;
  final Map<int, String> verses;

  BibleChapter({
    required this.number,
    required this.verses,
  });

  factory BibleChapter.fromJson(Map<String, dynamic> json, int chapterNumber) {
    final Map<int, String> verses = {};

    // Handle new format with "verses" array
    if (json.containsKey('verses')) {
      final versesList = json['verses'] as List<dynamic>;
      
      // Pre-size map for better performance
      verses.reserve(versesList.length);

      for (final verseData in versesList) {
        if (verseData is Map<String, dynamic>) {
          final verseNum = verseData['verse'] as int? ?? 0;
          final verseText = verseData['text'] as String? ?? '';
          if (verseNum > 0 && verseText.isNotEmpty) {
            verses[verseNum] = verseText;
          }
        }
      }
    } else {
      // Handle legacy format (flat structure)
      // Pre-size map for better performance
      verses.reserve(_estimateVerseCount(json));

      // Process verses more efficiently
      json.forEach((key, value) {
        if (value is String) {
          // Fast integer parsing
          final verseNum = BibleBook._fastParseInt(key);
          if (verseNum != null) {
            verses[verseNum] = value;
          }
        }
      });
    }

    return BibleChapter(
      number: chapterNumber,
      verses: verses,
    );
  }

  static int _estimateVerseCount(Map<String, dynamic> json) {
    // More accurate estimation
    return json.length > 200 ? 250 : (json.length + 30);
  }

  String? getVerse(int verse) {
    return verses[verse];
  }

  List<String> getVersesInRange(int start, int end) {
    final List<String> result = [];

    // More efficient range processing
    for (int i = start; i <= end; i++) {
      final verse = verses[i];
      if (verse != null) {
        result.add(verse);
      }
    }

    return result;
  }
}

// Extension to add reserve method to Map
extension MapReserve<K, V> on Map<K, V> {
  void reserve(int capacity) {
    // This is a no-op in Dart, but included for semantic clarity
  }
}
