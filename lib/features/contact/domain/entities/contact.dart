import 'package:json_annotation/json_annotation.dart';

part 'contact.g.dart';

@JsonSerializable()
class Contact {
  String id;
  String name;
  String phoneNumber;
  String? location;
  double? latitude;
  double? longitude;
  String userId;
  String userName;
  DateTime createdAt;
  DateTime updatedAt;

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.location,
    this.latitude,
    this.longitude,
    required this.userId,
    required this.userName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) =>
      _$ContactFromJson(json);

  Map<String, dynamic> toJson() => _$ContactToJson(this);

  Contact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? location,
    double? latitude,
    double? longitude,
    String? userId,
    String? userName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
