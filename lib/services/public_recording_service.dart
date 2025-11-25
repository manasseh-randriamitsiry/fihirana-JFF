import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_recording.dart';

class PublicRecordingService {
  static final PublicRecordingService _instance =
      PublicRecordingService._internal();
  factory PublicRecordingService() => _instance;
  PublicRecordingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'public_recordings';

  /// Publish a recording to Firestore
  Future<bool> publishRecording(UserRecording recording) async {
    try {
      await _firestore.collection(_collectionName).doc(recording.id).set({
        'id': recording.id,
        'title': recording.title,
        'hymnId': recording.hymnId,
        'userId': recording.id, // You may want to get actual userId from auth
        'userName': recording.userName ?? 'Anonymous',
        'driveFileId': recording.driveFileId,
        'publicLink': recording.publicLink,
        'duration': recording.durationSeconds,
        'createdAt': FieldValue.serverTimestamp(),
        'downloads': 0,
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error publishing recording to Firestore: $e');
      }
      return false;
    }
  }

  /// Remove a recording from public listings
  Future<bool> unpublishRecording(String recordingId) async {
    try {
      await _firestore.collection(_collectionName).doc(recordingId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error unpublishing recording: $e');
      }
      return false;
    }
  }

  /// Get all public recordings
  Future<List<UserRecording>> getPublicRecordings({String? hymnId}) async {
    try {
      Query query = _firestore.collection(_collectionName);

      if (hymnId != null) {
        query = query.where('hymnId', isEqualTo: hymnId);
      }

      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserRecording(
          id: data['id'] ?? '',
          hymnId: data['hymnId'] ?? '',
          title: data['title'] ?? '',
          filePath: '', // Public recordings don't have local path
          durationSeconds: data['duration'] ?? 0,
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isPublic: true,
          driveFileId: data['driveFileId'],
          publicLink: data['publicLink'],
          userName: data['userName'],
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching public recordings: $e');
      }
      return [];
    }
  }

  /// Increment download count for a recording
  Future<void> incrementDownloadCount(String recordingId) async {
    try {
      await _firestore.collection(_collectionName).doc(recordingId).update({
        'downloads': FieldValue.increment(1),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error incrementing download count: $e');
      }
    }
  }

  /// Stream of public recordings for real-time updates
  Stream<List<UserRecording>> streamPublicRecordings({String? hymnId}) {
    Query query = _firestore.collection(_collectionName);

    if (hymnId != null) {
      query = query.where('hymnId', isEqualTo: hymnId);
    }

    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserRecording(
          id: data['id'] ?? '',
          hymnId: data['hymnId'] ?? '',
          title: data['title'] ?? '',
          filePath: '',
          durationSeconds: data['duration'] ?? 0,
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isPublic: true,
          driveFileId: data['driveFileId'],
          publicLink: data['publicLink'],
          userName: data['userName'],
        );
      }).toList();
    });
  }
}
