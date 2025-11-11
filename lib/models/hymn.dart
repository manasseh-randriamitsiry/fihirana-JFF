class Hymn {
  String id;
  String hymnNumber;
  String title;
  List<String> verses;
  String? bridge;
  String? hymnHint;
  DateTime createdAt;
  String createdBy;
  String? createdByEmail;

  Hymn({
    required this.id,
    required this.hymnNumber,
    required this.title,
    required this.verses,
    this.bridge,
    this.hymnHint,
    required this.createdAt,
    required this.createdBy,
    this.createdByEmail,
  });

  factory Hymn.fromJson(Map<String, dynamic> json, String id) {
    final List<String> verses = [];

    if (json['verses'] is Map<String, dynamic>) {
      final versesMap = json['verses'] as Map<String, dynamic>;

      // Filter only numeric keys and sort them
      final numericKeys = versesMap.keys
          .where((key) => int.tryParse(key) != null)
          .toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

      for (final key in numericKeys) {
        verses.add(versesMap[key].toString());
      }
    } else if (json['verses'] is List) {
      verses.addAll(List<String>.from(json['verses']));
    }

    // Extract chorus/bridge from JSON
    String? bridge = json['bridge']?.toString();
    if (bridge == null && json['chorus'] != null) {
      // If no bridge but chorus exists, use chorus as bridge
      bridge = json['chorus'].toString();
    }
    
    // Also check if chorus is in the verses map (for malformed data)
    if (bridge == null && json['verses'] is Map<String, dynamic>) {
      final versesMap = json['verses'] as Map<String, dynamic>;
      if (versesMap.containsKey('chorus')) {
        bridge = versesMap['chorus'].toString();
      } else if (versesMap.containsKey('refrain')) {
        bridge = versesMap['refrain'].toString();
      }
    }

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(json['createdAt'].toString());
    } catch (e) {
      createdAt = DateTime.now();
    }

    return Hymn(
      id: id,
      hymnNumber: (json['hymnNumber'] ?? json['number']).toString(),
      title: json['title'].toString(),
      verses: verses,
      bridge: bridge,
      hymnHint: json['hymnHint']?.toString(),
      createdAt: createdAt,
      createdBy: json['createdBy'].toString(),
      createdByEmail: json['createdByEmail']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Hymn && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
