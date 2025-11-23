import 'package:cloud_firestore/cloud_firestore.dart';

class Playlist {
  final String id;
  final String title;
  final DateTime date;
  final List<String> hymnIds;
  final String createdBy;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist({
    required this.id,
    required this.title,
    required this.date,
    required this.hymnIds,
    required this.createdBy,
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      title: json['title'] as String,
      date: (json['date'] as Timestamp).toDate(),
      hymnIds: List<String>.from(json['hymnIds'] ?? []),
      createdBy: json['createdBy'] as String,
      isPublic: json['isPublic'] ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'hymnIds': hymnIds,
      'createdBy': createdBy,
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Playlist copyWith({
    String? id,
    String? title,
    DateTime? date,
    List<String>? hymnIds,
    String? createdBy,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      hymnIds: hymnIds ?? this.hymnIds,
      createdBy: createdBy ?? this.createdBy,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
