class Note {
  String id;
  String hymnId;
  String userId;
  String content;
  DateTime createdAt;
  DateTime updatedAt;
  String userName; // Add userName field

  Note({
    required this.id,
    required this.hymnId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.userName, // Add userName parameter
  });

  // Factory method to create Note from JSON data
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      hymnId: json['hymnId'] as String,
      userId: json['userId'] as String,
      content: json['content'] as String? ?? '', // Handle null content
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
      userName: json['userName'] as String? ?? 'Anonymous', // Handle null userName
    );
  }

  // Method to convert Note to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hymnId': hymnId,
      'userId': userId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userName': userName, // Include userName in JSON
    };
  }

  // Copy with method for updating
  Note copyWith({
    String? id,
    String? hymnId,
    String? userId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName, // Add userName parameter
  }) {
    return Note(
      id: id ?? this.id,
      hymnId: hymnId ?? this.hymnId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName, // Copy userName
    );
  }
}