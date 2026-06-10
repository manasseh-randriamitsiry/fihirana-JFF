import 'package:fihirana/features/bible/domain/entities/bible.dart';

class BibleBookModel extends BibleBook {
  BibleBookModel({
    required super.name,
    required super.abbreviation,
    required super.chapters,
    required super.chapterData,
  });

  factory BibleBookModel.fromJson(Map<String, dynamic> json, String bookName) {
    return BibleBookModel(
      name: bookName,
      abbreviation: bookName.length >= 3
          ? bookName.substring(0, 3).toUpperCase()
          : bookName.toUpperCase(),
      chapters: json['chapters']?.length ?? 0,
      chapterData: {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'abbreviation': abbreviation,
      'chapters': chapters,
      'chapterData': chapterData.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }
}

class BibleChapterModel extends BibleChapter {
  BibleChapterModel({
    required super.number,
    required super.verses,
  });

  factory BibleChapterModel.fromJson(
      Map<String, dynamic> json, int chapterNumber) {
    return BibleChapterModel(
      number: chapterNumber,
      verses: {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'verses': verses.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }
}
