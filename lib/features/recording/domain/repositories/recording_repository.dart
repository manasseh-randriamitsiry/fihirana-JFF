import 'package:fihirana/features/recording/domain/entities/user_recording.dart';

/// Abstract interface for recording repository operations
/// This allows for dependency injection and better testability
abstract class RecordingRepository {
  /// Observable list of user recordings
  List<UserRecording> get recordings;
  
  /// Observable list of public recordings
  List<UserRecording> get publicRecordings;
  
  /// Observable list of deleted recordings
  List<UserRecording> get deletedRecordings;
  
  /// Recording state
  bool get isRecording;
  
  /// Initialize the service
  Future<void> initialize();
  
  /// Start recording audio
  Future<String> startRecording();
  
  /// Stop recording and save the audio
  Future<UserRecording?> stopRecording();
  
  /// Cancel current recording
  Future<void> cancelRecording();
  
  /// Load all recordings from local storage
  Future<void> loadRecordings();
  
  /// Load public recordings from Firestore
  Future<void> loadPublicRecordings();
  
  /// Load deleted recordings
  Future<void> loadDeletedRecordings();
  
  /// Save a recording to local storage
  Future<void> saveRecording(UserRecording recording);
  
  /// Update an existing recording
  Future<void> updateRecording(UserRecording recording);
  
  /// Delete a recording (move to deleted)
  Future<void> deleteRecording(String recordingId);
  
  /// Permanently delete a recording
  Future<void> permanentlyDeleteRecording(String recordingId);

  /// Permanently delete multiple recordings
  Future<void> permanentlyDeleteMultipleRecordings(List<String> recordingIds);

  /// Restore a deleted recording
  Future<void> restoreRecording(String recordingId);
  
  /// Upload recording to Google Drive
  Future<bool> uploadToGoogleDrive(UserRecording recording);
  
  /// Toggle recording privacy (public/private)
  Future<void> toggleRecordingPrivacy(String recordingId, bool isPublic);
  
  /// Get recording by ID
  UserRecording? getRecordingById(String id);
  
  /// Search recordings by title or tags
  List<UserRecording> searchRecordings(String query);
  
  /// Get recordings by hymn ID
  List<UserRecording> getRecordingsByHymnId(String hymnId);
  
  /// Clear all recordings (for testing purposes)
  Future<void> clearAllRecordings();
  
  /// Additional methods for recording management
  Future<void> pauseRecording();
  Future<void> resumeRecording();
  Future<UserRecording> saveDriveRecording(UserRecording recording);
  Future<void> deleteLocalRecording(String id);
  Future<void> deleteLocalRecordingPermanently(String id);
  Future<void> refreshPublicUrls();
  
  /// Public recording management methods
  Future<bool> publishRecording(UserRecording recording);
  Future<void> unpublishRecording(String recordingId);
  
  /// Drive sync methods
  Future<void> syncFromDrive({bool force = false});
}