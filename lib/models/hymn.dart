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

  // Factory method to create Hymn from JSON data
  factory Hymn.fromJson(Map<String, dynamic> json, String id) {
    final List<String> verses = [];
    
    // Handle verses from JSON structure
    if (json['verses'] is Map<String, dynamic>) {
      final versesMap = json['verses'] as Map<String, dynamic>;
      // Sort verse keys numerically
      final sortedKeys = versesMap.keys.toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      
      for (final key in sortedKeys) {
        verses.add(versesMap[key].toString());
      }
    } else if (json['verses'] is List) {
      verses.addAll(List<String>.from(json['verses']));
    }

    // Extract chorus if it exists and add it as the last verse
    if (json['chorus'] != null) {
      verses.add(json['chorus'].toString());
    }

    return Hymn(
      id: id,
      hymnNumber: json['number'].toString(),
      title: json['title'].toString(),
      verses: verses,
      bridge: json['bridge']?.toString(),
      hymnHint: json['hint']?.toString(),
      createdAt: DateTime.now(),
      createdBy: 'Local File',
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
}