import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory Hymn.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    final createdAtData = data['createdAt'];
    return Hymn(
      id: doc.id,
      hymnNumber: data['hymnNumber'].toString(),
      title: data['title'] as String,
      verses: List<String>.from(data['verses'] as List<dynamic>),
      bridge: data['bridge'] as String?,
      hymnHint: data['hymnHint'] as String?,
      createdAt: createdAtData != null 
          ? (createdAtData as Timestamp).toDate() 
          : DateTime(2023), // Default date for legacy data
      createdBy: data['createdBy'] as String? ?? 'Unknown',
      createdByEmail: data['createdByEmail'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
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

  Map<String, dynamic> toFirestoreDocument() {
    return {
      'hymnNumber': hymnNumber,
      'title': title,
      'verses': verses,
      'bridge': bridge,
      'hymnHint': hymnHint,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'createdByEmail': createdByEmail,
    };
  }
}
