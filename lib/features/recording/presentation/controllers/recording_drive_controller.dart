import 'package:get/get.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/domain/usecases/recording_usecases.dart';

/// Controller responsible for Google Drive operations
class RecordingDriveController extends GetxController {
  final UploadToGoogleDriveUseCase uploadToGoogleDriveUseCase;
  final SyncFromDriveUseCase syncFromDriveUseCase;

  final RxBool _isUploading = false.obs;
  final RxString _lastError = ''.obs;
  final RxSet<String> _uploadingRecordingIds = <String>{}.obs;
  final RxMap<String, String> _uploadErrors = <String, String>{}.obs;

  RecordingDriveController({
    required this.uploadToGoogleDriveUseCase,
    required this.syncFromDriveUseCase,
  });

  // Getters
  bool get isUploading => _isUploading.value;
  String get lastError => _lastError.value;
  Set<String> get uploadingRecordingIds => _uploadingRecordingIds;
  Map<String, String> get uploadErrors => _uploadErrors;

  Future<bool> uploadToDrive(UserRecording recording) async {
    try {
      _uploadingRecordingIds.add(recording.id);
      _uploadErrors.remove(recording.id);
      _lastError.value = '';

      final success = await uploadToGoogleDriveUseCase(recording);
      if (!success) {
        _uploadErrors[recording.id] = 'Upload failed';
      }
      return success;
    } catch (e) {
      _uploadErrors[recording.id] = 'Upload error: $e';
      _lastError.value = 'Failed to upload recording: $e';
      return false;
    } finally {
      _uploadingRecordingIds.remove(recording.id);
    }
  }

  Future<void> syncFromDrive({bool force = false}) async {
    try {
      _isUploading.value = true;
      _lastError.value = '';
      await syncFromDriveUseCase(force: force);
    } catch (e) {
      _lastError.value = 'Failed to sync from drive: $e';
      rethrow;
    } finally {
      _isUploading.value = false;
    }
  }

  bool isUploadingRecording(String recordingId) {
    return _uploadingRecordingIds.contains(recordingId);
  }

  String? getUploadError(String recordingId) {
    return _uploadErrors[recordingId];
  }

  void clearError() {
    _lastError.value = '';
  }

  void clearUploadError(String recordingId) {
    _uploadErrors.remove(recordingId);
  }
}