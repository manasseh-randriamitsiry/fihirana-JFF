import 'package:json_annotation/json_annotation.dart';

part 'daily_verse.g.dart';

@JsonSerializable()
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

  factory DailyVerse.fromJson(Map<String, dynamic> json) =>
      _$DailyVerseFromJson(json);

  Map<String, dynamic> toJson() => _$DailyVerseToJson(this);

  @override
  String toString() {
    return '$reference\n$text';
  }
}
