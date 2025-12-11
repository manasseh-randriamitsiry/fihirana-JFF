import 'package:cloud_firestore/cloud_firestore.dart';

class Playlist {
  final String id;
  final String title;
  final DateTime date;
  final List<String> hymnIds;
  final String createdBy;
  final String? description;
  final bool isPublic;
  final bool isLocal; // New field to distinguish local vs Firebase playlists
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist({
    required this.id,
    required this.title,
    required this.date,
    required this.hymnIds,
    required this.createdBy,
    this.description,
    this.isPublic = false,
    this.isLocal = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] is Timestamp
          ? (json['date'] as Timestamp).toDate()
          : DateTime.parse(json['date'] as String),
      hymnIds: List<String>.from(json['hymnIds'] ?? []),
      createdBy: json['createdBy'] as String? ?? '',
      description: json['description'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      isLocal: json['isLocal'] as bool? ?? false,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'hymnIds': hymnIds,
      'createdBy': createdBy,
      'description': description,
      'isPublic': isPublic,
      'isLocal': isLocal,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'hymnIds': hymnIds,
      'createdBy': createdBy,
      'description': description,
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
    String? description,
    bool? isPublic,
    bool? isLocal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      hymnIds: hymnIds ?? this.hymnIds,
      createdBy: createdBy ?? this.createdBy,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      isLocal: isLocal ?? this.isLocal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
