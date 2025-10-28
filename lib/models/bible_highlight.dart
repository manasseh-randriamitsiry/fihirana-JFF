class BibleHighlight {
  String id;
  String bookName;
  int chapter;
  int startVerse;
  int endVerse;
  String userId;
  String userName;
  String color;
  DateTime createdAt;
  DateTime updatedAt;

  BibleHighlight({
    required this.id,
    required this.bookName,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    required this.userId,
    required this.userName,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory method to create BibleHighlight from JSON data
  factory BibleHighlight.fromJson(Map<String, dynamic> json) {
    return BibleHighlight(
      id: json['id'] as String,
      bookName: json['bookName'] as String,
      chapter: json['chapter'] as int,
      startVerse: json['startVerse'] as int,
      endVerse: json['endVerse'] as int,
      userId: json['userId'] as String,
      userName: json['userName'] as String? ?? 'Anonymous',
      color: json['color'] as String? ?? '#FF0000',
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  // Method to convert BibleHighlight to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookName': bookName,
      'chapter': chapter,
      'startVerse': startVerse,
      'endVerse': endVerse,
      'userId': userId,
      'userName': userName,
      'color': color,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copy with method for updating
  BibleHighlight copyWith({
    String? id,
    String? bookName,
    int? chapter,
    int? startVerse,
    int? endVerse,
    String? userId,
    String? userName,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BibleHighlight(
      id: id ?? this.id,
      bookName: bookName ?? this.bookName,
      chapter: chapter ?? this.chapter,
      startVerse: startVerse ?? this.startVerse,
      endVerse: endVerse ?? this.endVerse,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Check if a verse is within this highlight range
  bool containsVerse(int verse) {
    return verse >= startVerse && verse <= endVerse;
  }
  
  // Get highlight range as string
  String getRangeString() {
    if (startVerse == endVerse) {
      return '$bookName $chapter:$startVerse';
    } else {
      return '$bookName $chapter:$startVerse-$endVerse';
    }
  }
}