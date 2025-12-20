// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bible_highlight.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BibleHighlight _$BibleHighlightFromJson(Map<String, dynamic> json) =>
    BibleHighlight(
      id: json['id'] as String,
      bookName: json['bookName'] as String,
      chapter: (json['chapter'] as num).toInt(),
      startVerse: (json['startVerse'] as num).toInt(),
      endVerse: (json['endVerse'] as num).toInt(),
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      color: json['color'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$BibleHighlightToJson(BibleHighlight instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookName': instance.bookName,
      'chapter': instance.chapter,
      'startVerse': instance.startVerse,
      'endVerse': instance.endVerse,
      'userId': instance.userId,
      'userName': instance.userName,
      'color': instance.color,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
