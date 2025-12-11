/// Admin statistics entity
class AdminStats {
  final int totalUsers;
  final int activeUsers;
  final int totalHymns;
  final int installations;
  final int totalRecordings;
  final int deletedRecordings;
  final DateTime lastUpdated;

  const AdminStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalHymns,
    required this.installations,
    this.totalRecordings = 0,
    this.deletedRecordings = 0,
    required this.lastUpdated,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminStats &&
        other.totalUsers == totalUsers &&
        other.activeUsers == activeUsers &&
        other.totalHymns == totalHymns &&
        other.installations == installations &&
        other.totalRecordings == totalRecordings &&
        other.deletedRecordings == deletedRecordings &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return totalUsers.hashCode ^
        activeUsers.hashCode ^
        totalHymns.hashCode ^
        installations.hashCode ^
        totalRecordings.hashCode ^
        deletedRecordings.hashCode ^
        lastUpdated.hashCode;
  }

  AdminStats copyWith({
    int? totalUsers,
    int? activeUsers,
    int? totalHymns,
    int? installations,
    int? totalRecordings,
    int? deletedRecordings,
    DateTime? lastUpdated,
  }) {
    return AdminStats(
      totalUsers: totalUsers ?? this.totalUsers,
      activeUsers: activeUsers ?? this.activeUsers,
      totalHymns: totalHymns ?? this.totalHymns,
      installations: installations ?? this.installations,
      totalRecordings: totalRecordings ?? this.totalRecordings,
      deletedRecordings: deletedRecordings ?? this.deletedRecordings,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'totalHymns': totalHymns,
      'installations': installations,
      'totalRecordings': totalRecordings,
      'deletedRecordings': deletedRecordings,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory AdminStats.fromMap(Map<String, dynamic> map) {
    return AdminStats(
      totalUsers: map['totalUsers'] ?? 0,
      activeUsers: map['activeUsers'] ?? 0,
      totalHymns: map['totalHymns'] ?? 0,
      installations: map['installations'] ?? 0,
      totalRecordings: map['totalRecordings'] ?? 0,
      deletedRecordings: map['deletedRecordings'] ?? 0,
      lastUpdated: DateTime.parse(map['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }
}