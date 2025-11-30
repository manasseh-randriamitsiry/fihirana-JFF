import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/models/user_recording.dart';
import 'package:uuid/uuid.dart';

class DeletedRecordingService {
  static final DeletedRecordingService _instance =
      DeletedRecordingService._internal();
  factory DeletedRecordingService() => _instance;
  DeletedRecordingService._internal();

  final String _deletedKey = 'deleted_recordings';
  final Uuid _uuid = const Uuid();
  SharedPreferences? _prefs;

  // Initialize service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Save a deleted recording
  Future<void> saveDeletedRecording(UserRecording recording) async {
    try {
      if (_prefs == null) await initialize();

      final deletedRecording = recording.copyWith(
        id: _uuid.v4(), // Generate new ID for deleted recording
      );

      final List<Map<String, dynamic>> deletedRecordings =
          await getDeletedRecordingsMap();
      deletedRecordings.add(deletedRecording.toMap());

      await _prefs!.setString(_deletedKey, json.encode(deletedRecordings));
    } catch (e) {
      developer.log('Error saving deleted recording: $e');
    }
  }

  // Get all deleted recordings as maps
  Future<List<Map<String, dynamic>>> getDeletedRecordingsMap() async {
    try {
      if (_prefs == null) await initialize();

      final String? data = _prefs!.getString(_deletedKey);
      if (data == null || data.isEmpty) return [];

      final List<dynamic> decoded = json.decode(data);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      developer.log('Error getting deleted recordings: $e');
      return [];
    }
  }

  // Get all deleted recordings as UserRecording objects
  Future<List<UserRecording>> getDeletedRecordings() async {
    try {
      final List<Map<String, dynamic>> data = await getDeletedRecordingsMap();
      return data.map((map) => UserRecording.fromMap(map)).toList();
    } catch (e) {
      developer.log('Error getting deleted recordings: $e');
      return [];
    }
  }

  // Restore a deleted recording
  Future<void> restoreRecording(String deletedRecordingId) async {
    try {
      final List<Map<String, dynamic>> deletedRecordings =
          await getDeletedRecordingsMap();
      deletedRecordings
          .removeWhere((recording) => recording['id'] == deletedRecordingId);
      await _prefs!.setString(_deletedKey, json.encode(deletedRecordings));
    } catch (e) {
      developer.log('Error restoring recording: $e');
    }
  }

  // Permanently delete a recording from deleted list
  Future<void> permanentlyDeleteRecording(String deletedRecordingId) async {
    try {
      final List<Map<String, dynamic>> deletedRecordings =
          await getDeletedRecordingsMap();
      deletedRecordings
          .removeWhere((recording) => recording['id'] == deletedRecordingId);
      await _prefs!.setString(_deletedKey, json.encode(deletedRecordings));
    } catch (e) {
      developer.log('Error permanently deleting recording: $e');
    }
  }

  // Clear all deleted recordings
  Future<void> clearAllDeletedRecordings() async {
    try {
      await _prefs!.remove(_deletedKey);
    } catch (e) {
      developer.log('Error clearing deleted recordings: $e');
    }
  }

  // Get count of deleted recordings
  Future<int> getDeletedRecordingsCount() async {
    final recordings = await getDeletedRecordings();
    return recordings.length;
  }

  // Check if a recording exists in deleted list
  Future<bool> isRecordingDeleted(String originalRecordingId) async {
    try {
      final List<Map<String, dynamic>> deletedRecordings =
          await getDeletedRecordingsMap();
      return deletedRecordings.any((recording) =>
          recording['id'] == originalRecordingId ||
          recording['title'] == originalRecordingId);
    } catch (e) {
      developer.log('Error checking if recording is deleted: $e');
      return false;
    }
  }
}
