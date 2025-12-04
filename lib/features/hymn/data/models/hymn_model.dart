import 'package:fihirana/features/hymn/domain/entities/hymn.dart';

class HymnModel extends Hymn {
  HymnModel({
    required super.id,
    required super.hymnNumber,
    required super.title,
    required super.verses,
    super.bridge,
    super.hymnHint,
    required super.createdAt,
    required super.createdBy,
    super.createdByEmail,
  });

  factory HymnModel.fromJson(Map<String, dynamic> json, String id) {
    return HymnModel(
      id: id,
      hymnNumber: (json['hymnNumber'] ?? json['number'] ?? '').toString(),
      title: json['title']?.toString() ?? '',
      verses: [],
      bridge: json['bridge']?.toString(),
      hymnHint: json['hymnHint']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now(),
      createdBy: json['createdBy']?.toString() ?? 'Unknown',
      createdByEmail: json['createdByEmail']?.toString(),
    );
  }

  factory HymnModel.fromEntity(Hymn hymn) {
    return HymnModel(
      id: hymn.id,
      hymnNumber: hymn.hymnNumber,
      title: hymn.title,
      verses: hymn.verses,
      bridge: hymn.bridge,
      hymnHint: hymn.hymnHint,
      createdAt: hymn.createdAt,
      createdBy: hymn.createdBy,
      createdByEmail: hymn.createdByEmail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hymnNumber': hymnNumber,
      'title': title,
      'verses': verses,
      'bridge': bridge,
      'hymnHint': hymnHint,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'createdByEmail': createdByEmail,
    };
  }

  Hymn toEntity() {
    return Hymn(
      id: id,
      hymnNumber: hymnNumber,
      title: title,
      verses: verses,
      bridge: bridge,
      hymnHint: hymnHint,
      createdAt: createdAt,
      createdBy: createdBy,
      createdByEmail: createdByEmail,
    );
  }
}