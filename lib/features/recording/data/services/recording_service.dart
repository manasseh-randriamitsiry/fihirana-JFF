import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/data/services/google_drive_service.dart';
import 'package:fihirana/features/recording/domain/repositories/i_recording_service.dart';
import 'package:fihirana/features/recording/data/services/audio_config.dart';

class RecordingService extends GetxService implements IRecordingService {
  static RecordingService get to => Get.find();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final Uuid _uuid = const Uuid();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _publicCollectionName = 'public_recordings';
  static const String _deletedKey = 'deleted_recordings';

// State
  @override
  final RxList<UserRecording> recordings = <UserRecording>[].obs;
  @override
  final RxList<UserRecording> publicRecordings = <UserRecording>[].obs;
  @override
  final RxList<UserRecording> deletedRecordings = <UserRecording>[].obs;

  @override
  bool get isRecording => _isRecording.value;
  final RxBool _isRecording = false.obs;
  
  // Track current recording file path
  String? _currentRecordingPath;

@override
  void onInit() {
    super.onInit();
    loadRecordings();
    _loadDeletedRecordings();
  }

  @override
  Future<void> initialize() async {
    await loadRecordings();
  }

  // ===========================================================================
  // Local Recording Management (formerly UserRecordingService)
  // ===========================================================================

  @override
  Future<void> loadRecordings() async {
    try {
      final file = await _getMetadataFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final List<dynamic> jsonList = json.decode(content);
          var loadedRecordings =
              jsonList.map((e) => UserRecording.fromMap(e)).toList();

          // Deduplication logic
          final uniqueRecordings = <String, UserRecording>{};
          final noDriveIdRecordings = <UserRecording>[];

          for (final recording in loadedRecordings) {
            if (recording.driveFileId != null &&
                recording.driveFileId!.isNotEmpty) {
              if (!uniqueRecordings.containsKey(recording.driveFileId!)) {
                uniqueRecordings[recording.driveFileId!] = recording;
              }
            } else {
              noDriveIdRecordings.add(recording);
            }
          }

          loadedRecordings = [
            ...uniqueRecordings.values,
            ...noDriveIdRecordings
          ];
          loadedRecordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          recordings.assignAll(loadedRecordings);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error loading local recordings: $e');
    }
  }

  Future<void> _saveMetadata() async {
    try {
      final file = await _getMetadataFile();
      final jsonList = recordings.map((e) => e.toMap()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      if (kDebugMode) print('Error saving recordings metadata: $e');
    }
  }

  Future<File> _getMetadataFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(path.join(directory.path, 'user_recordings.json'));
  }

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  @override
  Future<String> startRecording() async {
    try {
      if (!await hasPermission()) {
        if (kDebugMode) print('RecordingService: No recording permission');
        throw Exception('Recording permission not granted');
      }

      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory(path.join(directory.path, 'recordings'));
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      // Enhanced format selection based on device type
      String fileName;
      RecordConfig config;
      
      if (await AudioConfig.isEmulator) {
        // Use WAV format for emulator compatibility
        fileName = 'rec_${DateTime.now().millisecondsSinceEpoch}.wav';
        config = const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          bitRate: 128000,
        );
        if (kDebugMode) {
          print('RecordingService: Using WAV format for emulator');
        }
      } else {
        // Use AAC format for physical devices
        final format = await AudioConfig.preferredFormat;
        fileName = 'rec_${DateTime.now().millisecondsSinceEpoch}$format';
        config = const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        );
        if (kDebugMode) {
          print('RecordingService: Using AAC format for physical device: $format');
        }
      }

      final filePath = path.join(recordingsDir.path, fileName);

      // Enhanced recording with retry logic
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          await _audioRecorder.start(config, path: filePath);
          _isRecording.value = true;
          _currentRecordingPath = filePath;
          
          if (kDebugMode) {
            print('RecordingService: Recording started successfully at: $filePath');
            print('RecordingService: Config - encoder: ${config.encoder}, sampleRate: ${config.sampleRate}');
          }
          return filePath;
        } catch (e) {
          retryCount++;
          if (kDebugMode) {
            print('RecordingService: Recording attempt $retryCount failed: $e');
          }
          
          if (retryCount >= maxRetries) {
            // Try fallback format for emulator
            if (await AudioConfig.isEmulator && config.encoder != AudioEncoder.wav) {
              if (kDebugMode) {
                print('RecordingService: Trying fallback to WAV format...');
              }
              final fallbackFileName = 'rec_${DateTime.now().millisecondsSinceEpoch}.wav';
              final fallbackPath = path.join(recordingsDir.path, fallbackFileName);
              const fallbackConfig = RecordConfig(encoder: AudioEncoder.wav);
              
              await _audioRecorder.start(fallbackConfig, path: fallbackPath);
              _isRecording.value = true;
              _currentRecordingPath = fallbackPath;
              
              if (kDebugMode) {
                print('RecordingService: Fallback recording started at: $fallbackPath');
              }
              return fallbackPath;
            }
            rethrow;
          }
          
          // Brief delay before retry
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
      }
      
      throw Exception('Failed to start recording after $maxRetries attempts');
    } catch (e) {
      if (kDebugMode) print('RecordingService: Error starting recording: $e');
      _isRecording.value = false;
      _currentRecordingPath = null;
      rethrow;
    }
  }

  @override
  Future<UserRecording?> stopRecording() async {
    try {
      if (kDebugMode) print('RecordingService: Stopping recording, current path: $_currentRecordingPath');
      
      await _audioRecorder.stop();
      _isRecording.value = false;
      
      // Create a UserRecording object if we have a file path
      if (_currentRecordingPath != null) {
        // Verify the file exists
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          final recording = UserRecording(
            id: _uuid.v4(),
            hymnId: '', // Will be set by operations manager
            title: '', // Will be set by operations manager
            filePath: _currentRecordingPath!,
            durationSeconds: 0, // Will be set by operations manager
            createdAt: DateTime.now(),
          );
          
          _currentRecordingPath = null; // Clear path
          if (kDebugMode) print('RecordingService: Recording stopped and UserRecording created');
          return recording;
        } else {
          if (kDebugMode) print('RecordingService: Recording file does not exist at path: $_currentRecordingPath');
          _currentRecordingPath = null;
          return null;
        }
      } else {
        if (kDebugMode) print('RecordingService: No current recording path available');
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('RecordingService: Error stopping recording: $e');
      _isRecording.value = false;
      _currentRecordingPath = null;
      return null;
    }
  }



@override
  Future<void> saveRecording(UserRecording recording) async {
    recordings.insert(0, recording);
    await _saveMetadata();
  }

  @override
  Future<void> cancelRecording() async {
    await _audioRecorder.stop();
    _isRecording.value = false;
    
    // Clean up the recording file if it exists
    if (_currentRecordingPath != null) {
      try {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        if (kDebugMode) print('Error deleting cancelled recording: $e');
      }
      _currentRecordingPath = null;
    }
  }

  @override
  Future<void> loadPublicRecordings() async {
    try {
      final recordings = await getPublicRecordings();
      publicRecordings.assignAll(recordings);
      if (kDebugMode) {
        print('RecordingService: Loaded ${recordings.length} public recordings');
      }
    } catch (e) {
      if (kDebugMode) print('Error loading public recordings: $e');
      publicRecordings.clear();
    }
  }

  @override
  Future<void> loadDeletedRecordings() async {
    await _loadDeletedRecordings();
  }

  @override


  @override
  Future<void> deleteRecording(String recordingId) async {
    recordings.removeWhere((r) => r.id == recordingId);
    await _saveMetadata();
  }

  @override
  Future<void> permanentlyDeleteRecording(String recordingId) async {
    deletedRecordings.removeWhere((r) => r.id == recordingId);
    await _saveMetadata();
  }

  @override
  Future<void> restoreRecording(String recordingId) async {
    final deleted = deletedRecordings.firstWhereOrNull((r) => r.id == recordingId);
    if (deleted != null) {
      deletedRecordings.removeWhere((r) => r.id == recordingId);
      recordings.insert(0, deleted);
      await _saveMetadata();
    }
  }

  @override
  Future<bool> uploadToGoogleDrive(UserRecording recording) async {
    try {
      final driveService = GoogleDriveService();
      final file = File(recording.filePath);
      
      if (!await file.exists()) {
        if (kDebugMode) print('Recording file not found: ${recording.filePath}');
        return false;
      }
      
      final fileId = await driveService.uploadFile(
        file,
        '${recording.title}.m4a',
        description: 'Hymn: ${recording.hymnId}',
      );
      
      if (fileId != null) {
        final publicLink = await driveService.getPublicLink(fileId);
        final webLink = await driveService.getWebViewLink(fileId);
        
        final updatedRecording = recording.copyWith(
          driveFileId: fileId,
          driveWebLink: webLink,
          publicLink: publicLink,
        );
        
        await updateRecording(updatedRecording);
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) print('Error uploading to Google Drive: $e');
      return false;
    }
  }

  @override
  Future<void> toggleRecordingPrivacy(String recordingId, bool isPublic) async {
    final index = recordings.indexWhere((r) => r.id == recordingId);
    if (index != -1) {
      recordings[index] = recordings[index].copyWith(isPublic: isPublic);
      await _saveMetadata();
    }
  }

  @override
  UserRecording? getRecordingById(String id) {
    try {
      return recordings.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  List<UserRecording> searchRecordings(String query) {
    return recordings.where((r) => 
      r.title.toLowerCase().contains(query.toLowerCase()) ||
      r.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()))
    ).toList();
  }

  @override
  List<UserRecording> getRecordingsByHymnId(String hymnId) {
    return recordings.where((r) => r.hymnId == hymnId).toList();
  }

  @override
  Future<void> clearAllRecordings() async {
    recordings.clear();
    publicRecordings.clear();
    deletedRecordings.clear();
    await _saveMetadata();
  }

  @override
  Future<void> pauseRecording() async {
    await _audioRecorder.pause();
  }

  @override
  Future<void> resumeRecording() async {
    await _audioRecorder.resume();
  }

  @override
  Future<UserRecording> saveDriveRecording(UserRecording recording) async {
    if (recording.driveFileId != null) {
      final existingIndex =
          recordings.indexWhere((r) => r.driveFileId == recording.driveFileId);
      if (existingIndex != -1) {
        recordings[existingIndex] = recording;
        await _saveMetadata();
        return recording;
      }
    }

    final existingIdIndex = recordings.indexWhere((r) => r.id == recording.id);
    if (existingIdIndex != -1) {
      recordings[existingIdIndex] = recording;
      await _saveMetadata();
      return recording;
    }

    recordings.insert(0, recording);
    await _saveMetadata();
    return recording;
  }

  @override
  Future<void> deleteLocalRecording(String id) async {
    final index = recordings.indexWhere((r) => r.id == id);
    if (index != -1) {
      final recording = recordings[index];

      // Move to deleted before removing
      await saveDeletedRecording(recording);

      try {
        final file = File(recording.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        if (kDebugMode) print('Error deleting recording file: $e');
      }

      recordings.removeAt(index);
      await _saveMetadata();
    }
  }

  @override
  Future<void> deleteLocalRecordingPermanently(String id) async {
    final index = recordings.indexWhere((r) => r.id == id);
    if (index != -1) {
      final recording = recordings[index];

      try {
        final file = File(recording.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        if (kDebugMode) print('Error deleting recording file: $e');
      }

      recordings.removeAt(index);
      await _saveMetadata();
    }
  }

  @override
  Future<void> refreshPublicUrls() async {
    final driveService = GoogleDriveService();
    bool updated = false;
    final List<UserRecording> currentRecordings = [...recordings];

    for (int i = 0; i < currentRecordings.length; i++) {
      final recording = currentRecordings[i];
      if (recording.isPublic && recording.driveFileId != null) {
        try {
          final newUrl =
              await driveService.getPublicLink(recording.driveFileId!);
          if (newUrl != null && newUrl != recording.publicLink) {
            currentRecordings[i] = recording.copyWith(publicLink: newUrl);
            updated = true;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to refresh URL for ${recording.id}: $e');
          }
        }
      }
    }

    if (updated) {
      recordings.assignAll(currentRecordings);
      await _saveMetadata();
    }
  }



  // ===========================================================================
  // Public Recording Management (formerly PublicRecordingService)
  // ===========================================================================

  Future<bool> titleExistsForHymn(String hymnId, String title,
      {String? excludeId}) async {
    try {
      Query query = _firestore
          .collection(_publicCollectionName)
          .where('hymnId', isEqualTo: hymnId)
          .where('title', isEqualTo: title);

      final snapshot = await query.get();
      if (excludeId != null) {
        return snapshot.docs.any((doc) => doc.id != excludeId);
      }
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) print('Error checking title existence: $e');
      return false;
    }
  }

  @override
  Future<bool> publishRecording(UserRecording recording) async {
    try {
      await _firestore.collection(_publicCollectionName).doc(recording.id).set({
        'id': recording.id,
        'title': recording.title,
        'hymnId': recording.hymnId,
        'userId': recording
            .id, // Note: Logic from original service used recording.id as userId? Verify.
        'userName': recording.userName ?? 'Anonymous',
        'driveFileId': recording.driveFileId,
        'publicLink': recording.publicLink,
        'duration': recording.durationSeconds,
        'createdAt': FieldValue.serverTimestamp(),
        'downloads': 0,
      });
      return true;
    } catch (e) {
      if (kDebugMode) print('Error publishing recording: $e');
      return false;
    }
  }

  Future<bool> updateRecordingTitle(String recordingId, String newTitle) async {
    try {
      await _firestore
          .collection(_publicCollectionName)
          .doc(recordingId)
          .update({
        'title': newTitle,
      });
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating recording title: $e');
      return false;
    }
  }

  @override
  Future<bool> unpublishRecording(String recordingId) async {
    try {
      await _firestore
          .collection(_publicCollectionName)
          .doc(recordingId)
          .delete();
      return true;
    } catch (e) {
      if (kDebugMode) print('Error unpublishing recording: $e');
      return false;
    }
  }

  Future<List<UserRecording>> getPublicRecordings({String? hymnId}) async {
    try {
      Query query = _firestore.collection(_publicCollectionName);
      if (hymnId != null) {
        query = query.where('hymnId', isEqualTo: hymnId);
      }
      query = query.orderBy('createdAt', descending: true);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => _mapFirestoreDocToRecording(doc))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching public recordings: $e');
      return [];
    }
  }

  Future<void> incrementDownloadCount(String recordingId) async {
    try {
      await _firestore
          .collection(_publicCollectionName)
          .doc(recordingId)
          .update({
        'downloads': FieldValue.increment(1),
      });
    } catch (e) {
      if (kDebugMode) print('Error incrementing download count: $e');
    }
  }

  Stream<List<UserRecording>> streamPublicRecordings({String? hymnId}) {
    Query query = _firestore.collection(_publicCollectionName);
    if (hymnId != null) {
      query = query.where('hymnId', isEqualTo: hymnId);
    }
    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => _mapFirestoreDocToRecording(doc))
          .toList();
    });
  }

  UserRecording _mapFirestoreDocToRecording(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserRecording(
      id: data['id'] ?? '',
      hymnId: data['hymnId'] ?? '',
      title: data['title'] ?? '',
      filePath: '',
      durationSeconds: data['duration'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublic: true,
      driveFileId: data['driveFileId'],
      publicLink: data['publicLink'],
      userName: data['userName'],
    );
  }

  // ===========================================================================
  // Deleted Recording Management (formerly DeletedRecordingService)
  // ===========================================================================

  Future<void> _loadDeletedRecordings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString(_deletedKey);
      if (data != null && data.isNotEmpty) {
        final List<dynamic> decoded = json.decode(data);
        final List<UserRecording> loaded =
            decoded.map((e) => UserRecording.fromMap(e)).toList();
        deletedRecordings.assignAll(loaded);
      }
    } catch (e) {
      if (kDebugMode) print('Error loading deleted recordings: $e');
    }
  }

  Future<void> saveDeletedRecording(UserRecording recording) async {
    try {
      final deletedRecording = recording.copyWith(
        id: _uuid.v4(),
      );
      deletedRecordings.add(deletedRecording);
      await _saveDeletedMetadata();
    } catch (e) {
      if (kDebugMode) print('Error saving deleted recording: $e');
    }
  }



  Future<void> clearAllDeletedRecordings() async {
    try {
      deletedRecordings.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_deletedKey);
    } catch (e) {
      if (kDebugMode) print('Error clearing deleted recordings: $e');
    }
  }

  Future<void> _saveDeletedMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = deletedRecordings.map((e) => e.toMap()).toList();
    await prefs.setString(_deletedKey, json.encode(jsonList));
  }

@override
  Future<void> updateRecording(UserRecording recording) async {
    final index = recordings.indexWhere((r) => r.id == recording.id);
    if (index != -1) {
      recordings[index] = recording;
      await _saveMetadata();
    }
  }

  @override
  Future<void> syncFromDrive({bool force = false}) async {
    // Implementation for syncing from Drive
    // This would be implemented in the service layer
    if (kDebugMode) {
      print('RecordingService: syncFromDrive called with force: $force');
    }
  }

}
