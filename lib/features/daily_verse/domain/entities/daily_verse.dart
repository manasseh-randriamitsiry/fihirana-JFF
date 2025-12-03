class DailyVerse {
  final String book;
  final int chapter;
  final int verse;
  final String text;
  final String reference;
  final DateTime date;

  DailyVerse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.reference,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'book': book,
      'chapter': chapter,
      'verse': verse,
      'text': text,
      'reference': reference,
      'date': date.toIso8601String(),
    };
  }

  factory DailyVerse.fromJson(Map<String, dynamic> json) {
    return DailyVerse(
      book: json['book'] as String,
      chapter: json['chapter'] as int,
      verse: json['verse'] as int,
      text: json['text'] as String,
      reference: json['reference'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  @override
  String toString() {
    return '$reference\n$text';
  }
}
