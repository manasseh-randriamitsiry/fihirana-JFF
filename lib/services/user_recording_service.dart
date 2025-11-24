import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import '../models/user_recording.dart';

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
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = json.decode(content);
        _recordings = jsonList.map((e) => UserRecording.fromMap(e)).toList();
        _recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _recordingsController.add(_recordings);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading recordings metadata: $e');
      }
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
    );

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
}
