import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String createdBy;
  final String createdByEmail;

  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.expiresAt,
    required this.createdBy,
    required this.createdByEmail,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'createdBy': createdBy,
      'createdByEmail': createdByEmail,
    };
  }

  /// Null when the stored document cannot be read as an announcement. Rows can
  /// be written by the console or by an older build, and one unreadable row
  /// must not take the whole announcement list down with it.
  static Announcement? tryFromFirestore(DocumentSnapshot doc) =>
      tryFromData(doc.data(), id: doc.id);

  /// The parse itself, separated from the Firestore snapshot so a stored map
  /// can be checked without a live document.
  static Announcement? tryFromData(Object? data, {required String id}) {
    if (data is! Map<String, dynamic>) return null;

    final createdAt = data['createdAt'];
    if (createdAt is! Timestamp) return null;

    final expiresAt = data['expiresAt'];
    final title = data['title'];
    final message = data['message'];
    final createdBy = data['createdBy'];
    final createdByEmail = data['createdByEmail'];

    if (title is! String || message is! String) return null;

    return Announcement(
      id: id,
      title: title,
      message: message,
      createdAt: createdAt.toDate(),
      expiresAt: expiresAt is Timestamp ? expiresAt.toDate() : null,
      createdBy: createdBy is String ? createdBy : '',
      createdByEmail: createdByEmail is String ? createdByEmail : '',
    );
  }

  bool isExpired() {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool isActive() {
    return !isExpired();
  }
}
