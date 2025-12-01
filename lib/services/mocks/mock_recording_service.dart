import 'dart:async';
import 'package:fihirana/models/user_recording.dart';
import '../interfaces/irecording_service.dart';

/// Mock implementation of RecordingService for testing
class MockRecordingService implements IRecordingService {
  @override
  List<UserRecording> get recordings => _recordings;
  final List<UserRecording> _recordings = [];

  @override
  List<UserRecording> get publicRecordings => _publicRecordings;
  final List<UserRecording> _publicRecordings = [];

  @override
  List<UserRecording> get deletedRecordings => _deletedRecordings;
  final List<UserRecording> _deletedRecordings = [];

  @override
  bool get isRecording => _isRecording;
  bool _isRecording = false;

  @override
  Future<void> initialize() async {
    // Mock initialization
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<String> startRecording() async {
    _isRecording = true;
    return 'mock_recording_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<UserRecording?> stopRecording() async {
    _isRecording = false;
    final recording = UserRecording(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      hymnId: 'mock_hymn_1',
      title: 'Mock Recording',
      filePath: '/mock/path/recording.mp3',
      durationSeconds: 10,
      createdAt: DateTime.now(),
    );
    _recordings.add(recording);
    return recording;
  }

  @override
  Future<void> cancelRecording() async {
    _isRecording = false;
  }

  @override
  Future<void> loadRecordings() async {
    // Mock loading
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<void> loadPublicRecordings() async {
    // Mock loading
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<void> loadDeletedRecordings() async {
    // Mock loading
    await Future.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<void> saveRecording(UserRecording recording) async {
    _recordings.add(recording);
  }

  @override
  Future<void> updateRecording(UserRecording recording) async {
    final index = _recordings.indexWhere((r) => r.id == recording.id);
    if (index != -1) {
      _recordings[index] = recording;
    }
  }

  @override
  Future<void> deleteRecording(String recordingId) async {
    final recording = _recordings.firstWhere((r) => r.id == recordingId);
    _recordings.removeWhere((r) => r.id == recordingId);
    _deletedRecordings.add(recording);
  }

  @override
  Future<void> permanentlyDeleteRecording(String recordingId) async {
    _recordings.removeWhere((r) => r.id == recordingId);
    _deletedRecordings.removeWhere((r) => r.id == recordingId);
  }

  @override
  Future<void> restoreRecording(String recordingId) async {
    final recording = _deletedRecordings.firstWhere((r) => r.id == recordingId);
    _deletedRecordings.removeWhere((r) => r.id == recordingId);
    _recordings.add(recording);
  }

  @override
  Future<bool> uploadToGoogleDrive(UserRecording recording) async {
    // Mock upload
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  @override
  Future<void> toggleRecordingPrivacy(String recordingId, bool isPublic) async {
    final recording = _recordings.firstWhere((r) => r.id == recordingId);
    final index = _recordings.indexWhere((r) => r.id == recordingId);
    if (index != -1) {
      _recordings[index] = recording.copyWith(isPublic: isPublic);
    }
  }

  @override
  UserRecording? getRecordingById(String id) {
    try {
      return _recordings.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  List<UserRecording> searchRecordings(String query) {
    return _recordings.where((r) => 
      r.title.toLowerCase().contains(query.toLowerCase()) ||
      r.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()))
    ).toList();
  }

  @override
  List<UserRecording> getRecordingsByHymnId(String hymnId) {
    return _recordings.where((r) => r.hymnId == hymnId).toList();
  }

  @override
  Future<void> clearAllRecordings() async {
    _recordings.clear();
    _publicRecordings.clear();
    _deletedRecordings.clear();
  }

  // Missing interface methods
  @override
  Future<void> deleteLocalRecording(String id) async {
    _recordings.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> deleteLocalRecordingPermanently(String id) async {
    _recordings.removeWhere((r) => r.id == id);
    _deletedRecordings.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> pauseRecording() async {
    // Mock pause
    _isRecording = false;
  }

  @override
  Future<void> resumeRecording() async {
    // Mock resume
    _isRecording = true;
  }

  @override
  Future<UserRecording> saveDriveRecording(UserRecording recording) async {
    _recordings.add(recording);
    return recording;
  }

  @override
  Future<void> refreshPublicUrls() async {
    // Mock refresh
    await Future.delayed(const Duration(milliseconds: 100));
  }
}