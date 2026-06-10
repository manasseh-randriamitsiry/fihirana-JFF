/// User management entity
class AdminUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final bool isAdmin;
  final bool isBlocked;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const AdminUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.isAdmin = false,
    this.isBlocked = false,
    this.lastLogin,
    required this.createdAt,
    this.metadata = const {},
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminUser &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.isAdmin == isAdmin &&
        other.isBlocked == isBlocked &&
        other.lastLogin == lastLogin &&
        other.createdAt == createdAt &&
        other.metadata == metadata;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        photoUrl.hashCode ^
        isAdmin.hashCode ^
        isBlocked.hashCode ^
        lastLogin.hashCode ^
        createdAt.hashCode ^
        metadata.hashCode;
  }

  AdminUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAdmin,
    bool? isBlocked,
    DateTime? lastLogin,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAdmin: isAdmin ?? this.isAdmin,
      isBlocked: isBlocked ?? this.isBlocked,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'isAdmin': isAdmin,
      'isBlocked': isBlocked,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      isAdmin: map['isAdmin'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      lastLogin:
          map['lastLogin'] != null ? DateTime.parse(map['lastLogin']) : null,
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}
