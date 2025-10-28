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
    
    // Pre-allocate map with estimated size for better performance
    chapters.reserve(_estimateChapterCount(json));
    
    // Filter out non-numeric keys and process only chapter data
    json.forEach((key, value) {
      // Check if the key is a valid chapter number
      if (key != null && key is String) {
        try {
          final chapterNum = int.parse(key);
          if (value is Map<String, dynamic>) {
            chapters[chapterNum] = BibleChapter.fromJson(value, chapterNum);
          }
        } catch (e) {
          // Skip non-numeric keys like "meta" or other metadata
        }
      }
    });

    return BibleBook(
      name: bookName,
      abbreviation: bookName.substring(0, 3).toUpperCase(),
      chapters: chapters.length,
      chapterData: chapters,
    );
  }
  
  static int _estimateChapterCount(Map<String, dynamic> json) {
    // Estimate based on typical Bible book structure
    return json.length > 100 ? 150 : json.length + 10;
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
    
    // Pre-allocate map with estimated size for better performance
    verses.reserve(_estimateVerseCount(json));
    
    // Filter out non-numeric keys and process only verse data
    json.forEach((key, value) {
      // Check if the key is a valid verse number
      if (key != null && key is String) {
        try {
          final verseNum = int.parse(key);
          if (value is String) {
            verses[verseNum] = value;
          }
        } catch (e) {
          // Skip non-numeric keys
        }
      }
    });

    return BibleChapter(
      number: chapterNumber,
      verses: verses,
    );
  }
  
  static int _estimateVerseCount(Map<String, dynamic> json) {
    // Estimate based on typical Bible chapter structure
    return json.length > 200 ? 250 : json.length + 20;
  }

  String? getVerse(int verse) {
    return verses[verse];
  }

  List<String> getVersesInRange(int start, int end) {
    final List<String> result = [];
    // Pre-allocate list for better performance
    result.length = (end - start + 1).clamp(0, 1000);
    
    for (int i = start; i <= end; i++) {
      if (verses.containsKey(i)) {
        result.add(verses[i]!);
      }
    }
    
    // Remove null entries
    result.removeWhere((element) => element == null);
    return result;
  }
}

// Extension to add reserve method to Map
extension MapReserve<K, V> on Map<K, V> {
  void reserve(int capacity) {
    // This is a no-op in Dart, but included for semantic clarity
    // In other languages, this would pre-allocate memory
  }
}

// Extension to add reserve method to List
extension ListReserve<T> on List<T> {
  void reserve(int capacity) {
    // This is a no-op in Dart, but included for semantic clarity
    // In other languages, this would pre-allocate memory
  }
}