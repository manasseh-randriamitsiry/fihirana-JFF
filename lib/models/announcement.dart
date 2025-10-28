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

  factory Announcement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    Timestamp? expiresAtTimestamp = data['expiresAt'];

    return Announcement(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: expiresAtTimestamp?.toDate(),
      createdBy: data['createdBy'] ?? '',
      createdByEmail: data['createdByEmail'] ?? '',
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