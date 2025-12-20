// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contact_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactModel _$ContactModelFromJson(Map<String, dynamic> json) => ContactModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ContactModelToJson(ContactModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phoneNumber': instance.phoneNumber,
      'location': instance.location,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'userId': instance.userId,
      'userName': instance.userName,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
