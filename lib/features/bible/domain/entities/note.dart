import 'package:json_annotation/json_annotation.dart';

part 'note.g.dart';

@JsonSerializable()
class Note {
  String id;
  String hymnId;
  String userId;
  String userEmail;
  String content;
  DateTime createdAt;
  DateTime updatedAt;
  String userName; // Add userName field

  Note({
    required this.id,
    required this.hymnId,
    required this.userId,
    required this.userEmail,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.userName, // Add userName parameter
  });

  factory Note.fromJson(Map<String, dynamic> json) =>
      _$NoteFromJson(json);

  Map<String, dynamic> toJson() => _$NoteToJson(this);

// Copy with method for updating
  Note copyWith({
    String? id,
    String? hymnId,
    String? userId,
    String? userEmail,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName, // Add userName parameter
  }) {
    return Note(
      id: id ?? this.id,
      hymnId: hymnId ?? this.hymnId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName, // Copy userName
    );
  }
}