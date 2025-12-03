import 'package:fihirana/features/recording/domain/repositories/recording_repository.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/data/services/recording_service.dart';

/// Implementation of the recording repository
class RecordingRepositoryImpl implements RecordingRepository {
  final RecordingService _recordingService;

  RecordingRepositoryImpl({RecordingService? recordingService})
      : _recordingService = recordingService ?? RecordingService.to;

  @override
  List<UserRecording> get recordings => _recordingService.recordings;

  @override
  List<UserRecording> get publicRecordings => _recordingService.publicRecordings;

  @override
  List<UserRecording> get deletedRecordings => _recordingService.deletedRecordings;

  @override
  bool get isRecording => _recordingService.isRecording;

  @override
  Future<void> initialize() async {
    return await _recordingService.initialize();
  }

  @override
  Future<String> startRecording() async {
    return await _recordingService.startRecording();
  }

  @override
  Future<UserRecording?> stopRecording() async {
    return await _recordingService.stopRecording();
  }

  @override
  Future<void> cancelRecording() async {
    return await _recordingService.cancelRecording();
  }

  @override
  Future<void> loadRecordings() async {
    return await _recordingService.loadRecordings();
  }

  @override
  Future<void> loadPublicRecordings() async {
    return await _recordingService.loadPublicRecordings();
  }

  @override
  Future<void> loadDeletedRecordings() async {
    return await _recordingService.loadDeletedRecordings();
  }

  @override
  Future<void> saveRecording(UserRecording recording) async {
    return await _recordingService.saveRecording(recording);
  }

  @override
  Future<void> updateRecording(UserRecording recording) async {
    return await _recordingService.updateRecording(recording);
  }

  @override
  Future<void> deleteRecording(String recordingId) async {
    return await _recordingService.deleteRecording(recordingId);
  }

  @override
  Future<void> permanentlyDeleteRecording(String recordingId) async {
    return await _recordingService.permanentlyDeleteRecording(recordingId);
  }

  @override
  Future<void> restoreRecording(String recordingId) async {
    return await _recordingService.restoreRecording(recordingId);
  }

  @override
  Future<bool> uploadToGoogleDrive(UserRecording recording) async {
    return await _recordingService.uploadToGoogleDrive(recording);
  }

  @override
  Future<void> toggleRecordingPrivacy(String recordingId, bool isPublic) async {
    return await _recordingService.toggleRecordingPrivacy(recordingId, isPublic);
  }

  @override
  UserRecording? getRecordingById(String id) {
    return _recordingService.getRecordingById(id);
  }

  @override
  List<UserRecording> searchRecordings(String query) {
    return _recordingService.searchRecordings(query);
  }

  @override
  List<UserRecording> getRecordingsByHymnId(String hymnId) {
    return _recordingService.getRecordingsByHymnId(hymnId);
  }

  @override
  Future<void> clearAllRecordings() async {
    return await _recordingService.clearAllRecordings();
  }

  @override
  Future<void> pauseRecording() async {
    return await _recordingService.pauseRecording();
  }

  @override
  Future<void> resumeRecording() async {
    return await _recordingService.resumeRecording();
  }

  @override
  Future<UserRecording> saveDriveRecording(UserRecording recording) async {
    return await _recordingService.saveDriveRecording(recording);
  }

  @override
  Future<void> deleteLocalRecording(String id) async {
    return await _recordingService.deleteLocalRecording(id);
  }

  @override
  Future<void> deleteLocalRecordingPermanently(String id) async {
    return await _recordingService.deleteLocalRecordingPermanently(id);
  }

  @override
  Future<void> refreshPublicUrls() async {
    return await _recordingService.refreshPublicUrls();
  }

  // Additional methods for public recording management
  @override
  Future<bool> publishRecording(UserRecording recording) async {
    return await _recordingService.publishRecording(recording);
  }

  @override
  Future<void> unpublishRecording(String recordingId) async {
    await _recordingService.unpublishRecording(recordingId);
  }

  @override
  Future<void> syncFromDrive({bool force = false}) async {
    // Implementation for syncing from Drive
    // This would be implemented in the service layer
  }
}