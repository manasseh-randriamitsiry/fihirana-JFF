import 'dart:async';
import 'package:get/get.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/domain/usecases/recording_usecases.dart';

/// Main controller for recording feature using DI pattern
class RecordingController extends GetxController {
  // Use cases
  final StartRecordingUseCase startRecordingUseCase;
  final StopRecordingUseCase stopRecordingUseCase;
  final CancelRecordingUseCase cancelRecordingUseCase;
  final LoadRecordingsUseCase loadRecordingsUseCase;
  final SaveRecordingUseCase saveRecordingUseCase;
  final UpdateRecordingUseCase updateRecordingUseCase;
  final DeleteRecordingUseCase deleteRecordingUseCase;
  final GetRecordingByIdUseCase getRecordingByIdUseCase;
  final LoadPublicRecordingsUseCase loadPublicRecordingsUseCase;
  final PublishRecordingUseCase publishRecordingUseCase;
  final UnpublishRecordingUseCase unpublishRecordingUseCase;
  final ToggleRecordingPrivacyUseCase toggleRecordingPrivacyUseCase;
  final SearchRecordingsUseCase searchRecordingsUseCase;
  final GetRecordingsByHymnIdUseCase getRecordingsByHymnIdUseCase;
  final UploadToGoogleDriveUseCase uploadToGoogleDriveUseCase;
  final SyncFromDriveUseCase syncFromDriveUseCase;
  final LoadDeletedRecordingsUseCase loadDeletedRecordingsUseCase;
  final RestoreRecordingUseCase restoreRecordingUseCase;
  final PermanentlyDeleteRecordingUseCase permanentlyDeleteRecordingUseCase;

  // State management
  final RxBool _isRecording = false.obs;
  final RxBool _isPaused = false.obs;
  final RxInt _recordDuration = 0.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isUploading = false.obs;
  final RxString _lastError = ''.obs;
  final RxBool _overlayVisible = false.obs;
  final RxBool _isOverlayMinimized = false.obs;
  final RxString _currentHymnId = ''.obs;
  final RxString _currentHymnTitle = ''.obs;
  final RxBool _playerOverlayVisible = false.obs;
  final RxBool _isPlayerMinimized = false.obs;
  final Rxn<UserRecording> _currentRecording = Rxn<UserRecording>();
  final RxSet<String> _uploadingRecordingIds = <String>{}.obs;
  final RxMap<String, String> _uploadErrors = <String, String>{}.obs;

  // Timer for recording duration
  Timer? _recordingTimer;

  RecordingController({
    required this.startRecordingUseCase,
    required this.stopRecordingUseCase,
    required this.cancelRecordingUseCase,
    required this.loadRecordingsUseCase,
    required this.saveRecordingUseCase,
    required this.updateRecordingUseCase,
    required this.deleteRecordingUseCase,
    required this.getRecordingByIdUseCase,
    required this.loadPublicRecordingsUseCase,
    required this.publishRecordingUseCase,
    required this.unpublishRecordingUseCase,
    required this.toggleRecordingPrivacyUseCase,
    required this.searchRecordingsUseCase,
    required this.getRecordingsByHymnIdUseCase,
    required this.uploadToGoogleDriveUseCase,
    required this.syncFromDriveUseCase,
    required this.loadDeletedRecordingsUseCase,
    required this.restoreRecordingUseCase,
    required this.permanentlyDeleteRecordingUseCase,
  });

  // Getters for state
  bool get isRecording => _isRecording.value;
  bool get isPaused => _isPaused.value;
  int get recordDuration => _recordDuration.value;
  bool get isLoading => _isLoading.value;
  bool get isUploading => _isUploading.value;
  String get lastError => _lastError.value;
  bool get overlayVisible => _overlayVisible.value;
  bool get isOverlayMinimized => _isOverlayMinimized.value;
  String get currentHymnId => _currentHymnId.value;
  String get currentHymnTitle => _currentHymnTitle.value;
  bool get playerOverlayVisible => _playerOverlayVisible.value;
  bool get isPlayerMinimized => _isPlayerMinimized.value;
  UserRecording? get currentRecording => _currentRecording.value;
  Set<String> get uploadingRecordingIds => _uploadingRecordingIds;
  Map<String, String> get uploadErrors => _uploadErrors;

  // Data getters (these would be connected to repository streams in a real implementation)
  RxList<UserRecording> get recordings => RxList<UserRecording>([]);
  RxList<UserRecording> get publicRecordings => RxList<UserRecording>([]);
  RxList<UserRecording> get deletedRecordings => RxList<UserRecording>([]);

  @override
  void onInit() {
    super.onInit();
    _loadData();
  }

  @override
  void onClose() {
    _recordingTimer?.cancel();
    super.onClose();
  }

  Future<void> _loadData() async {
    _isLoading.value = true;
    try {
      await Future.wait([
        loadRecordingsUseCase(),
        loadPublicRecordingsUseCase(),
        loadDeletedRecordingsUseCase(),
      ]);
    } catch (e) {
      _lastError.value = 'Failed to load data: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  // Recording methods
  Future<void> startRecording(String hymnId) async {
    try {
      _isLoading.value = true;
      _lastError.value = '';
      
      await startRecordingUseCase();
      _isRecording.value = true;
      _currentHymnId.value = hymnId;
      _startRecordingTimer();
      
      _showOverlay(hymnId, '');
    } catch (e) {
      _lastError.value = 'Failed to start recording: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<UserRecording?> stopRecording(String hymnId, String title) async {
    try {
      _isLoading.value = true;
      _lastError.value = '';
      
      final recording = await stopRecordingUseCase();
      if (recording != null) {
        final updatedRecording = recording.copyWith(
          hymnId: hymnId,
          title: title,
        );
        await saveRecordingUseCase(updatedRecording);
        
        _isRecording.value = false;
        _stopRecordingTimer();
        _hideOverlay();
        
        return updatedRecording;
      }
      return null;
    } catch (e) {
      _lastError.value = 'Failed to stop recording: $e';
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> pauseRecording() async {
    // Implementation would depend on repository
    _isPaused.value = true;
    _recordingTimer?.cancel();
  }

  Future<void> resumeRecording() async {
    // Implementation would depend on repository
    _isPaused.value = false;
    _startRecordingTimer();
  }

  Future<void> cancelRecording() async {
    try {
      await cancelRecordingUseCase();
      _isRecording.value = false;
      _stopRecordingTimer();
      _hideOverlay();
    } catch (e) {
      _lastError.value = 'Failed to cancel recording: $e';
    }
  }

  // CRUD methods
  Future<void> updateRecording(UserRecording recording) async {
    try {
      _isLoading.value = true;
      await updateRecordingUseCase(recording);
    } catch (e) {
      _lastError.value = 'Failed to update recording: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteRecording(UserRecording recording) async {
    try {
      _isLoading.value = true;
      await deleteRecordingUseCase(recording.id);
    } catch (e) {
      _lastError.value = 'Failed to delete recording: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  // Public recording methods
  Future<void> publishRecording(UserRecording recording) async {
    try {
      _isLoading.value = true;
      await publishRecordingUseCase(recording);
      await loadPublicRecordingsUseCase();
    } catch (e) {
      _lastError.value = 'Failed to publish recording: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> unpublishRecording(UserRecording recording) async {
    try {
      _isLoading.value = true;
      await unpublishRecordingUseCase(recording.id);
      await loadPublicRecordingsUseCase();
    } catch (e) {
      _lastError.value = 'Failed to unpublish recording: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  // Search methods
  List<UserRecording> searchRecordings(String query) {
    return searchRecordingsUseCase(query);
  }

  List<UserRecording> getRecordingsByHymnId(String hymnId) {
    return getRecordingsByHymnIdUseCase(hymnId);
  }

  // Drive methods
  Future<void> uploadToDrive(UserRecording recording) async {
    try {
      _uploadingRecordingIds.add(recording.id);
      _uploadErrors.remove(recording.id);
      
      final success = await uploadToGoogleDriveUseCase(recording);
      if (!success) {
        _uploadErrors[recording.id] = 'Upload failed';
      }
    } catch (e) {
      _uploadErrors[recording.id] = 'Upload error: $e';
    } finally {
      _uploadingRecordingIds.remove(recording.id);
    }
  }

  // Deleted recordings methods
  Future<void> restoreRecording(UserRecording deletedRecording) async {
    try {
      _isLoading.value = true;
      await restoreRecordingUseCase(deletedRecording.id);
      await _loadData();
    } catch (e) {
      _lastError.value = 'Failed to restore recording: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> permanentlyDeleteRecording(UserRecording deletedRecording) async {
    try {
      _isLoading.value = true;
      await permanentlyDeleteRecordingUseCase(deletedRecording.id);
      await _loadData();
    } catch (e) {
      _lastError.value = 'Failed to delete recording: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  // Overlay methods
  void showOverlay(String hymnId, String title) {
    _showOverlay(hymnId, title);
  }

  void hideOverlay() {
    _hideOverlay();
  }

  void minimizeOverlay() {
    _isOverlayMinimized.value = true;
  }

  void maximizeOverlay() {
    _isOverlayMinimized.value = false;
  }

  // Player methods
  void showPlayerOverlay(UserRecording recording) {
    _currentRecording.value = recording;
    _playerOverlayVisible.value = true;
  }

  void hidePlayerOverlay() {
    _playerOverlayVisible.value = false;
    _currentRecording.value = null;
  }

  void minimizePlayer() {
    _isPlayerMinimized.value = true;
  }

  void maximizePlayer() {
    _isPlayerMinimized.value = false;
  }

  // Private methods
  void _startRecordingTimer() {
    _recordDuration.value = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordDuration.value++;
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordDuration.value = 0;
  }

  void _showOverlay(String hymnId, String title) {
    _currentHymnId.value = hymnId;
    _currentHymnTitle.value = title;
    _overlayVisible.value = true;
    _isOverlayMinimized.value = false;
  }

  void _hideOverlay() {
    _overlayVisible.value = false;
    _isOverlayMinimized.value = false;
    _currentHymnId.value = '';
    _currentHymnTitle.value = '';
  }

  // Utility methods
  bool isUploadingRecording(String recordingId) {
    return _uploadingRecordingIds.contains(recordingId);
  }

  String? getUploadError(String recordingId) {
    return _uploadErrors[recordingId];
  }

  void clearError() {
    _lastError.value = '';
  }

  void refreshData() {
    _loadData();
  }
}