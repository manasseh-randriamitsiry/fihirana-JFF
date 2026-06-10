/// History item entity
class HistoryItem {
  final String id;
  final String hymnId;
  final String title;
  final String number;
  final DateTime timestamp;

  const HistoryItem({
    required this.id,
    required this.hymnId,
    required this.title,
    required this.number,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryItem &&
        other.id == id &&
        other.hymnId == hymnId &&
        other.title == title &&
        other.number == number &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        hymnId.hashCode ^
        title.hashCode ^
        number.hashCode ^
        timestamp.hashCode;
  }

  HistoryItem copyWith({
    String? id,
    String? hymnId,
    String? title,
    String? number,
    DateTime? timestamp,
  }) {
    return HistoryItem(
      id: id ?? this.id,
      hymnId: hymnId ?? this.hymnId,
      title: title ?? this.title,
      number: number ?? this.number,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hymnId': hymnId,
      'title': title,
      'number': number,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory HistoryItem.fromMap(Map<String, dynamic> map) {
    return HistoryItem(
      id: map['id'] ?? '',
      hymnId: map['hymnId'] ?? '',
      title: map['title'] ?? '',
      number: map['number'] ?? '',
      timestamp:
          DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}
