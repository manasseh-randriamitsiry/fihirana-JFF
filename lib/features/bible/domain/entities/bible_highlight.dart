import 'package:json_annotation/json_annotation.dart';

part 'bible_highlight.g.dart';

@JsonSerializable()
class BibleHighlight {
  String id;
  String bookName;
  int chapter;
  int startVerse;
  int endVerse;
  String userId;
  String userName;
  String color;
  DateTime createdAt;
  DateTime updatedAt;

  BibleHighlight({
    required this.id,
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.userId,
    required this.userName,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BibleHighlight.fromJson(Map<String, dynamic> json) =>
      _$BibleHighlightFromJson(json);

  Map<String, dynamic> toJson() => _$BibleHighlightToJson(this);

  // Copy with method for updating
  BibleHighlight copyWith({
    String? id,
    String? bookName,
    int? chapter,
    int? startVerse,
    int? endVerse,
    String? userId,
    String? userName,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BibleHighlight(
      id: id ?? this.id,
      bookName: bookName ?? this.bookName,
      chapter: chapter ?? this.chapter,
      startVerse: startVerse ?? this.startVerse,
      endVerse: endVerse ?? this.endVerse,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if a verse is within this highlight range
  bool containsVerse(int verse) {
    return verse >= startVerse && verse <= endVerse;
  }

  // Get highlight range as string
  String getRangeString() {
    if (startVerse == endVerse) {
      return '$bookName $chapter:$startVerse';
    } else {
      return '$bookName $chapter:$startVerse-$endVerse';
    }
  }
}
