class Contact {
  String id;
  String name;
  String phoneNumber;
  String? location;
  String userId;
  String userName;
  DateTime createdAt;
  DateTime updatedAt;

  Contact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.location,
    required this.userId,
    required this.userName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      location: json['location'] as String?,
      userId: json['userId'] as String,
      userName: json['userName'] as String? ?? 'Anonymous',
      createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'location': location,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Contact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? location,
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
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
