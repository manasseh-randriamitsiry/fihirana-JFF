class BibleShareVerseLine {
  final int number;
  final String text;

  const BibleShareVerseLine({
    required this.number,
    required this.text,
  });
}

class BibleShareData {
  final String bookName;
  final int chapter;
  final List<BibleShareVerseLine> verses;

  BibleShareData({
    required this.bookName,
    required this.chapter,
    required List<BibleShareVerseLine> verses,
  }) : verses = List.unmodifiable(verses);

  String get reference {
    if (bookName.isEmpty || chapter <= 0 || verses.isEmpty) {
      return '';
    }

    final verseNumbers = verses.map((verse) => verse.number).toList()..sort();

    final verseLabel = _buildVerseLabel(verseNumbers);
    return '$bookName $chapter:$verseLabel';
  }

  String get shareSubject => reference;

  String get shareText {
    final buffer = StringBuffer(reference);

    for (final verse in verses) {
      if (buffer.isNotEmpty) {
        buffer.writeln();
        buffer.writeln();
      }
      buffer.write('${verse.number}. ${verse.text}');
    }

    return buffer.toString().trim();
  }

  String get verseCountLabel {
    if (verses.isEmpty) {
      return '0 verses';
    }
    return verses.length == 1 ? '1 verse' : '${verses.length} verses';
  }

  String _buildVerseLabel(List<int> verseNumbers) {
    if (verseNumbers.length == 1) {
      return verseNumbers.first.toString();
    }

    final isContinuous = _isContinuous(verseNumbers);
    if (isContinuous) {
      return '${verseNumbers.first}-${verseNumbers.last}';
    }

    return verseNumbers.join(',');
  }

  bool _isContinuous(List<int> verseNumbers) {
    for (var index = 1; index < verseNumbers.length; index++) {
      if (verseNumbers[index] != verseNumbers[index - 1] + 1) {
        return false;
      }
    }
    return true;
  }
}
