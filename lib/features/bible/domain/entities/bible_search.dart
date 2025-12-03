enum BibleSearchContext {
  books,
  currentChapter,
  allBible,
}

enum BibleSearchResultType {
  book,
  verse,
}

class BibleSearchResult {
  final BibleSearchResultType type;
  final String bookName;
  final int chapter;
  final int verse;
  final String text;
  final double relevance;

  BibleSearchResult({
    required this.type,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.relevance,
  });

  String get displayText {
    switch (type) {
      case BibleSearchResultType.book:
        return bookName;
      case BibleSearchResultType.verse:
        return '$bookName $chapter:$verse';
    }
  }

  String get subtitle {
    switch (type) {
      case BibleSearchResultType.book:
        return 'Boky iray';
      case BibleSearchResultType.verse:
        return preview;
    }
  }

  String get highlightedText {
    if (type == BibleSearchResultType.book) {
      return bookName;
    }
    
    // For verses, we'll implement highlighting in the UI
    return text;
  }

  String get preview {
    if (type == BibleSearchResultType.book) {
      return 'Boky iray';
    }
    
    // Show first 100 characters of verse
    if (text.length <= 100) return text;
    return '${text.substring(0, 100)}...';
  }
}