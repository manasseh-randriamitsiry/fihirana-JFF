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
          // print('Skipping non-chapter key: $key');
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
          // print('Skipping non-verse key in chapter $chapterNumber: $key');
        }
      }
    });

    return BibleChapter(
      number: chapterNumber,
      verses: verses,
    );
  }

  String? getVerse(int verse) {
    return verses[verse];
  }

  List<String> getVersesInRange(int start, int end) {
    final List<String> result = [];
    for (int i = start; i <= end; i++) {
      if (verses.containsKey(i)) {
        result.add(verses[i]!);
      }
    }
    return result;
  }
}