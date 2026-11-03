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

  /// The reference is unique per search, so it is also what identifies a row
  /// when the corpus repeats a verse text in several places.
  String get listKey => '${type.name}:$displayText';
}
