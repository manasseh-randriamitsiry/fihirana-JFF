// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_verse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyVerse _$DailyVerseFromJson(Map<String, dynamic> json) => DailyVerse(
      book: json['book'] as String,
      chapter: (json['chapter'] as num).toInt(),
      verse: (json['verse'] as num).toInt(),
      text: json['text'] as String,
      reference: json['reference'] as String,
      date: DateTime.parse(json['date'] as String),
    );

Map<String, dynamic> _$DailyVerseToJson(DailyVerse instance) =>
    <String, dynamic>{
      'book': instance.book,
      'chapter': instance.chapter,
      'verse': instance.verse,
      'text': instance.text,
      'reference': instance.reference,
      'date': instance.date.toIso8601String(),
    };
