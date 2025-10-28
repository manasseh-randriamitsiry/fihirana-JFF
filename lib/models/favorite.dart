import 'package:cloud_firestore/cloud_firestore.dart';

class Favorite {
  String id;
  String hymnId;
  String userId;
  String userEmail;
  DateTime addedDate;

  Favorite({
    required this.id,
    required this.hymnId,
    required this.userId,
    required this.userEmail,
    required this.addedDate,
  });

  factory Favorite.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map<String, dynamic> data = doc.data()!;
    return Favorite(
      id: doc.id,
      hymnId: data['hymnId'] as String,
      userId: data['userId'] as String,
      userEmail: data['userEmail'] as String,
      addedDate: (data['addedDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'hymnId': hymnId,
      'userId': userId,
      'userEmail': userEmail,
      'addedDate': Timestamp.fromDate(addedDate),
    };
  }
  
  // Factory method to create a Favorite from basic data
  factory Favorite.create(String hymnId, String userId, String userEmail) {
    return Favorite(
      id: '', // Will be set by Firebase when saved
      hymnId: hymnId,
      userId: userId,
      userEmail: userEmail,
      addedDate: DateTime.now(),
    );
  }
}