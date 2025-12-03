import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/data/services/google_drive_service.dart';

class UserRecordingService {
  static final UserRecordingService _instance =
      UserRecordingService._internal();
  factory UserRecordingService() => _instance;
  UserRecordingService._internal();

  final AudioRecorder _audioRecorder = AudioRecorder();
  final _uuid = const Uuid();

  List<UserRecording> _recordings = [];
  bool _initialized = false;

  // Stream controller for recordings updates
  final _recordingsController =
      StreamController<List<UserRecording>>.broadcast();
  Stream<List<UserRecording>> get recordingsStream =>
      _recordingsController.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    await _loadRecordings();
    _initialized = true;
  }

  Future<void> _loadRecordings() async {
    try {
      final file = await _getMetadataFile();
      if (kDebugMode) {
        print('UserRecordingService: Loading recordings from ${file.path}');
        print('UserRecordingService: File exists: ${await file.exists()}');
      }

      if (await file.exists()) {
        final content = await file.readAsString();
        if (kDebugMode) {
          print('UserRecordingService: Content length: ${content.length}');
        }

        if (content.isNotEmpty) {
          final List<dynamic> jsonList = json.decode(content);
          _recordings = jsonList.map((e) => UserRecording.fromMap(e)).toList();

          // Deduplicate recordings based on driveFileId
          final uniqueRecordings = <String, UserRecording>{};
          final noDriveIdRecordings = <UserRecording>[];

          for (final recording in _recordings) {
            if (recording.driveFileId != null &&
                recording.driveFileId!.isNotEmpty) {
              // If duplicate exists, keep the one with more info or newer
              if (!uniqueRecordings.containsKey(recording.driveFileId!)) {
                uniqueRecordings[recording.driveFileId!] = recording;
              }
            } else {
              noDriveIdRecordings.add(recording);
            }
          }

          _recordings = [...uniqueRecordings.values, ...noDriveIdRecordings];
          _recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (kDebugMode) {
            print(
                'UserRecordingService: Loaded ${_recordings.length} recordings (after deduplication)');
          }
        } else {
          _recordings = [];
          if (kDebugMode) {
            print('UserRecordingService: No content found, empty list');
          }
        }
      } else {
        _recordings = [];
        if (kDebugMode) {
          print('UserRecordingService: File does not exist, empty list');
        }
      }

      // Always add to stream, even if empty
      _recordingsController.add(_recordings);
      if (kDebugMode) {
        print(
            'UserRecordingService: Added ${_recordings.length} recordings to stream');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading recordings metadata: $e');
      }
      // Ensure stream gets something even on error
      _recordingsController.add(_recordings);
    }
  }

  Future<void> _saveMetadata() async {
    try {
      final file = await _getMetadataFile();
      final jsonList = _recordings.map((e) => e.toMap()).toList();
      await file.writeAsString(json.encode(jsonList));
      _recordingsController.add(_recordings);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving recordings metadata: $e');
      }
    }
  }

  // Make _loadRecordings public for external calls
  Future<void> loadRecordings() async {
    await _loadRecordings();
  }

  Future<File> _getMetadataFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(path.join(directory.path, 'user_recordings.json'));
  }

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<void> startRecording(String hymnId) async {
    if (await hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory(path.join(directory.path, 'recordings'));
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      final fileName =
          'rec_${hymnId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = path.join(recordingsDir.path, fileName);

      await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath);
    }
  }

  Future<String?> stopRecording() async {
    return await _audioRecorder.stop();
  }

  Future<void> pauseRecording() async {
    await _audioRecorder.pause();
  }

  Future<void> resumeRecording() async {
    await _audioRecorder.resume();
  }

  Future<bool> isRecording() async {
    return await _audioRecorder.isRecording();
  }

  Future<UserRecording> saveRecording({
    required String filePath,
    required String hymnId,
    required String title,
    required int durationSeconds,
    bool isPublic = false,
    List<String> tags = const [],
    String? userId,
    String? userEmail,
    String? userPhotoUrl,
    String? userName,
  }) async {
    final recording = UserRecording(
      id: _uuid.v4(),
      hymnId: hymnId,
      title: title,
      filePath: filePath,
      durationSeconds: durationSeconds,
      createdAt: DateTime.now(),
      isPublic: isPublic,
      tags: tags,
      userId: userId,
      userEmail: userEmail,
      userPhotoUrl: userPhotoUrl,
      userName: userName,
    );

    if (kDebugMode) {
      print(
          'UserRecordingService: Saved recording with duration: $durationSeconds seconds');
    }

    _recordings.insert(0, recording);
    await _saveMetadata();
    return recording;
  }

  Future<UserRecording> saveDriveRecording(UserRecording recording) async {
    // Check for existing recording with same driveFileId
    if (recording.driveFileId != null) {
      final existingIndex =
          _recordings.indexWhere((r) => r.driveFileId == recording.driveFileId);

      if (existingIndex != -1) {
        // Update existing instead of inserting new
        _recordings[existingIndex] = recording;
        await _saveMetadata();
        return recording;
      }
    }

    // Check for existing recording with same ID
    final existingIdIndex = _recordings.indexWhere((r) => r.id == recording.id);
    if (existingIdIndex != -1) {
      _recordings[existingIdIndex] = recording;
      await _saveMetadata();
      return recording;
    }

    _recordings.insert(0, recording);
    await _saveMetadata();
    return recording;
  }

  Future<void> deleteRecording(String id) async {
    final index = _recordings.indexWhere((r) => r.id == id);
    if (index != -1) {
      final recording = _recordings[index];

      // Delete local file
      try {
        final file = File(recording.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error deleting recording file: $e');
        }
      }

      _recordings.removeAt(index);
      await _saveMetadata();
    }
  }

  Future<void> updateRecording(UserRecording recording) async {
    final index = _recordings.indexWhere((r) => r.id == recording.id);
    if (index != -1) {
      _recordings[index] = recording;
      await _saveMetadata();
    }
  }

  List<UserRecording> getRecordingsForHymn(String hymnId) {
    return _recordings.where((r) => r.hymnId == hymnId).toList();
  }

  List<UserRecording> getAllRecordings() {
    return List.unmodifiable(_recordings);
  }

  /// Refresh public URLs for recordings that have driveFileId but expired publicLink
  Future<void> refreshPublicUrls() async {
    if (kDebugMode) {
      print('UserRecordingService: Starting public URL refresh...');
    }

    final driveService = GoogleDriveService();
    bool updated = false;

    for (int i = 0; i < _recordings.length; i++) {
      final recording = _recordings[i];

      // Only refresh recordings that are public and have driveFileId
      if (recording.isPublic && recording.driveFileId != null) {
        try {
          final newUrl =
              await driveService.getPublicLink(recording.driveFileId!);
          if (newUrl != null && newUrl != recording.publicLink) {
            if (kDebugMode) {
              print('UserRecordingService: Refreshed URL for ${recording.id}');
              print('  Old: ${recording.publicLink}');
              print('  New: $newUrl');
            }

            _recordings[i] = recording.copyWith(publicLink: newUrl);
            updated = true;
          }
        } catch (e) {
          if (kDebugMode) {
            print(
                'UserRecordingService: Failed to refresh URL for ${recording.id}: $e');
          }
        }
      }
    }

    if (updated) {
      await _saveMetadata();
      _recordingsController.add(List.unmodifiable(_recordings));
      if (kDebugMode) {
        print('UserRecordingService: Public URL refresh completed and saved');
      }
    } else {
      if (kDebugMode) {
        print('UserRecordingService: No URLs needed refreshing');
      }
    }
  }
}
