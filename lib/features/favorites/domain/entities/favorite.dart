/// Favorite entity
class Favorite {
  final String id;
  final String hymnId;
  final String userId;
  final String userEmail;
  final DateTime addedDate;

  const Favorite({
    required this.id,
    required this.hymnId,
    required this.userId,
    required this.userEmail,
    required this.addedDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Favorite &&
        other.id == id &&
        other.hymnId == hymnId &&
        other.userId == userId &&
        other.userEmail == userEmail &&
        other.addedDate == addedDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        hymnId.hashCode ^
        userId.hashCode ^
        userEmail.hashCode ^
        addedDate.hashCode;
  }

  Favorite copyWith({
    String? id,
    String? hymnId,
    String? userId,
    String? userEmail,
    DateTime? addedDate,
  }) {
    return Favorite(
      id: id ?? this.id,
      hymnId: hymnId ?? this.hymnId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      addedDate: addedDate ?? this.addedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hymnId': hymnId,
      'userId': userId,
      'userEmail': userEmail,
      'addedDate': addedDate.toIso8601String(),
    };
  }

  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      id: map['id'] ?? '',
      hymnId: map['hymnId'] ?? '',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      addedDate:
          DateTime.parse(map['addedDate'] ?? DateTime.now().toIso8601String()),
    );
  }
}
