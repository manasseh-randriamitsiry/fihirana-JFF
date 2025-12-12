import 'package:fihirana/features/recording/domain/repositories/recording_repository.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:flutter/foundation.dart';

/// Use case for starting a recording
class StartRecordingUseCase {
  final RecordingRepository _repository;

  StartRecordingUseCase(this._repository);

  Future<String> call() async {
    return await _repository.startRecording();
  }
}

/// Use case for stopping a recording
class StopRecordingUseCase {
  final RecordingRepository _repository;

  StopRecordingUseCase(this._repository);

  Future<UserRecording?> call() async {
    return await _repository.stopRecording();
  }
}

/// Use case for canceling a recording
class CancelRecordingUseCase {
  final RecordingRepository _repository;

  CancelRecordingUseCase(this._repository);

  Future<void> call() async {
    return await _repository.cancelRecording();
  }
}

/// Use case for loading recordings
class LoadRecordingsUseCase {
  final RecordingRepository _repository;

  LoadRecordingsUseCase(this._repository);

  Future<void> call() async {
    return await _repository.loadRecordings();
  }
}

/// Use case for saving a recording
class SaveRecordingUseCase {
  final RecordingRepository _repository;

  SaveRecordingUseCase(this._repository);

  Future<void> call(UserRecording recording) async {
    return await _repository.saveRecording(recording);
  }
}

/// Use case for updating a recording
class UpdateRecordingUseCase {
  final RecordingRepository _repository;

  UpdateRecordingUseCase(this._repository);

  Future<void> call(UserRecording recording) async {
    return await _repository.updateRecording(recording);
  }
}

/// Use case for deleting a recording
class DeleteRecordingUseCase {
  final RecordingRepository _repository;

  DeleteRecordingUseCase(this._repository);

  Future<void> call(String recordingId) async {
    if (kDebugMode) {
      print('DeleteRecordingUseCase: called with id: $recordingId');
    }
    return await _repository.deleteRecording(recordingId);
  }
}

/// Use case for getting a recording by ID
class GetRecordingByIdUseCase {
  final RecordingRepository _repository;

  GetRecordingByIdUseCase(this._repository);

  UserRecording? call(String id) {
    return _repository.getRecordingById(id);
  }
}

/// Use case for loading public recordings
class LoadPublicRecordingsUseCase {
  final RecordingRepository _repository;

  LoadPublicRecordingsUseCase(this._repository);

  Future<void> call() async {
    return await _repository.loadPublicRecordings();
  }
}

/// Use case for publishing a recording
class PublishRecordingUseCase {
  final RecordingRepository _repository;

  PublishRecordingUseCase(this._repository);

  Future<void> call(UserRecording recording) async {
    await _repository.publishRecording(recording);
  }
}

/// Use case for unpublishing a recording
class UnpublishRecordingUseCase {
  final RecordingRepository _repository;

  UnpublishRecordingUseCase(this._repository);

  Future<void> call(String recordingId) async {
    return await _repository.unpublishRecording(recordingId);
  }
}

/// Use case for toggling recording privacy
class ToggleRecordingPrivacyUseCase {
  final RecordingRepository _repository;

  ToggleRecordingPrivacyUseCase(this._repository);

  Future<void> call(String recordingId, bool isPublic) async {
    return await _repository.toggleRecordingPrivacy(recordingId, isPublic);
  }
}

/// Use case for searching recordings
class SearchRecordingsUseCase {
  final RecordingRepository _repository;

  SearchRecordingsUseCase(this._repository);

  List<UserRecording> call(String query) {
    return _repository.searchRecordings(query);
  }
}

/// Use case for getting recordings by hymn ID
class GetRecordingsByHymnIdUseCase {
  final RecordingRepository _repository;

  GetRecordingsByHymnIdUseCase(this._repository);

  List<UserRecording> call(String hymnId) {
    return _repository.getRecordingsByHymnId(hymnId);
  }
}

/// Use case for uploading to Google Drive
class UploadToGoogleDriveUseCase {
  final RecordingRepository _repository;

  UploadToGoogleDriveUseCase(this._repository);

  Future<bool> call(UserRecording recording) async {
    return await _repository.uploadToGoogleDrive(recording);
  }
}

/// Use case for syncing from Drive
class SyncFromDriveUseCase {
  final RecordingRepository _repository;

  SyncFromDriveUseCase(this._repository);

  Future<void> call({bool force = false}) async {
    return await _repository.syncFromDrive(force: force);
  }
}

/// Use case for loading deleted recordings
class LoadDeletedRecordingsUseCase {
  final RecordingRepository _repository;

  LoadDeletedRecordingsUseCase(this._repository);

  Future<void> call() async {
    return await _repository.loadDeletedRecordings();
  }
}

/// Use case for restoring a recording
class RestoreRecordingUseCase {
  final RecordingRepository _repository;

  RestoreRecordingUseCase(this._repository);

  Future<void> call(String recordingId) async {
    return await _repository.restoreRecording(recordingId);
  }
}

/// Use case for permanently deleting a recording
class PermanentlyDeleteRecordingUseCase {
  final RecordingRepository _repository;

  PermanentlyDeleteRecordingUseCase(this._repository);

  Future<void> call(String recordingId) async {
    return await _repository.permanentlyDeleteRecording(recordingId);
  }
}

/// Use case for permanently deleting multiple recordings
class PermanentlyDeleteMultipleRecordingsUseCase {
  final RecordingRepository _repository;

  PermanentlyDeleteMultipleRecordingsUseCase(this._repository);

  Future<void> call(List<String> recordingIds) async {
    return await _repository.permanentlyDeleteMultipleRecordings(recordingIds);
  }
}