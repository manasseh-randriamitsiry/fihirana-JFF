// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FavoriteModel _$FavoriteModelFromJson(Map<String, dynamic> json) =>
    FavoriteModel(
      id: json['id'] as String,
      hymnId: json['hymnId'] as String,
      userId: json['userId'] as String,
      userEmail: json['userEmail'] as String,
      addedDate: DateTime.parse(json['addedDate'] as String),
    );

Map<String, dynamic> _$FavoriteModelToJson(FavoriteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hymnId': instance.hymnId,
      'userId': instance.userId,
      'userEmail': instance.userEmail,
      'addedDate': instance.addedDate.toIso8601String(),
    };
