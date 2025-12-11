import 'package:get/get.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/domain/usecases/recording_usecases.dart';

/// Controller responsible for recording publishing (public/private management)
class RecordingPublishingController extends GetxController {
  final PublishRecordingUseCase publishRecordingUseCase;
  final UnpublishRecordingUseCase unpublishRecordingUseCase;
  final ToggleRecordingPrivacyUseCase toggleRecordingPrivacyUseCase;
  final LoadPublicRecordingsUseCase loadPublicRecordingsUseCase;

  final RxBool _isLoading = false.obs;
  final RxString _lastError = ''.obs;
  final RxList<UserRecording> _publicRecordings = <UserRecording>[].obs;

  RecordingPublishingController({
    required this.publishRecordingUseCase,
    required this.unpublishRecordingUseCase,
    required this.toggleRecordingPrivacyUseCase,
    required this.loadPublicRecordingsUseCase,
  });

  // Getters
  bool get isLoading => _isLoading.value;
  String get lastError => _lastError.value;
  List<UserRecording> get publicRecordings => _publicRecordings;


  Future<void> publishRecording(UserRecording recording) async {
    try {
      _isLoading.value = true;
      _lastError.value = '';
      await publishRecordingUseCase(recording);

      // Add to public recordings if not already there
      if (!_publicRecordings.any((r) => r.id == recording.id)) {
        _publicRecordings.add(recording);
      }

      // Public recordings will be updated via streams
    } catch (e) {
      _lastError.value = 'Failed to publish recording: $e';
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> unpublishRecording(UserRecording recording) async {
    try {
      _isLoading.value = true;
      _lastError.value = '';
      await unpublishRecordingUseCase(recording.id);

      // Remove from public recordings
      _publicRecordings.removeWhere((r) => r.id == recording.id);

      // Public recordings will be updated via streams
    } catch (e) {
      _lastError.value = 'Failed to unpublish recording: $e';
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> toggleRecordingPrivacy(UserRecording recording) async {
    try {
      _isLoading.value = true;
      _lastError.value = '';
      await toggleRecordingPrivacyUseCase(recording.id, !recording.isPublic);

      // Reload public recordings to reflect changes
      refreshPublicRecordings();
    } catch (e) {
      _lastError.value = 'Failed to toggle recording privacy: $e';
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  void clearError() {
    _lastError.value = '';
  }

  Future<void> refreshPublicRecordings({String? hymnId}) async {
    try {
      _isLoading.value = true;
      _lastError.value = '';
      
      await loadPublicRecordingsUseCase();
      
      // If hymnId is provided, filter the recordings
      if (hymnId != null) {
        _publicRecordings.assignAll(_publicRecordings.where((recording) => recording.hymnId == hymnId));
      }
    } catch (e) {
      _lastError.value = 'Failed to refresh public recordings: $e';
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }
}