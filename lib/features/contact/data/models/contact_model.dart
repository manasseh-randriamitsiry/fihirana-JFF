import 'package:fihirana/features/contact/domain/entities/contact.dart';

/// Data model for contact
class ContactModel extends Contact {
  ContactModel({
    required super.id,
    required super.name,
    required super.phoneNumber,
    super.location,
    super.latitude,
    super.longitude,
    required super.userId,
    required super.userName,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      location: json['location'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      userId: json['userId'] as String,
      userName: json['userName'] as String? ?? 'Anonymous',
      createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Convert from domain entity
  factory ContactModel.fromEntity(Contact contact) {
    return ContactModel(
      id: contact.id,
      name: contact.name,
      phoneNumber: contact.phoneNumber,
      location: contact.location,
      latitude: contact.latitude,
      longitude: contact.longitude,
      userId: contact.userId,
      userName: contact.userName,
      createdAt: contact.createdAt,
      updatedAt: contact.updatedAt,
    );
  }

  /// Convert to domain entity
  Contact toEntity() {
    return Contact(
      id: id,
      name: name,
      phoneNumber: phoneNumber,
      location: location,
      latitude: latitude,
      longitude: longitude,
      userId: userId,
      userName: userName,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  ContactModel copyWith({
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
    return ContactModel(
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