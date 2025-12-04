import 'package:get/get.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/domain/usecases/recording_usecases.dart';
import 'recording_operations_controller.dart';
import 'recording_data_controller.dart';
import 'recording_publishing_controller.dart';
import 'recording_drive_controller.dart';
import 'recording_ui_controller.dart';

/// Main recording controller that orchestrates smaller, focused controllers
/// This maintains backward compatibility while using the new modular architecture
class RecordingController extends GetxController {
  // Sub-controllers
  late final RecordingOperationsController operationsController;
  late final RecordingDataController dataController;
  late final RecordingPublishingController publishingController;
  late final RecordingDriveController driveController;
  late final RecordingUIController uiController;

  // Use cases for DI
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

  @override
  void onInit() {
    super.onInit();
    _initializeSubControllers();
  }

  void _initializeSubControllers() {
    // Initialize sub-controllers with their respective use cases
    operationsController = Get.put(
      RecordingOperationsController(
        startRecordingUseCase: startRecordingUseCase,
        stopRecordingUseCase: stopRecordingUseCase,
        cancelRecordingUseCase: cancelRecordingUseCase,
        saveRecordingUseCase: saveRecordingUseCase,
      ),
      tag: 'recording_operations',
    );

    dataController = Get.put(
      RecordingDataController(
        loadRecordingsUseCase: loadRecordingsUseCase,
        updateRecordingUseCase: updateRecordingUseCase,
        deleteRecordingUseCase: deleteRecordingUseCase,
        getRecordingByIdUseCase: getRecordingByIdUseCase,
        loadDeletedRecordingsUseCase: loadDeletedRecordingsUseCase,
        restoreRecordingUseCase: restoreRecordingUseCase,
        permanentlyDeleteRecordingUseCase: permanentlyDeleteRecordingUseCase,
      ),
      tag: 'recording_data',
    );

    publishingController = Get.put(
      RecordingPublishingController(
        publishRecordingUseCase: publishRecordingUseCase,
        unpublishRecordingUseCase: unpublishRecordingUseCase,
        toggleRecordingPrivacyUseCase: toggleRecordingPrivacyUseCase,
      ),
      tag: 'recording_publishing',
    );

    driveController = Get.put(
      RecordingDriveController(
        uploadToGoogleDriveUseCase: uploadToGoogleDriveUseCase,
        syncFromDriveUseCase: syncFromDriveUseCase,
      ),
      tag: 'recording_drive',
    );

    uiController = Get.put(
      RecordingUIController(),
      tag: 'recording_ui',
    );
  }

  // Delegated properties for backward compatibility
  bool get isRecording => operationsController.isRecording;
  bool get isPaused => operationsController.isPaused;
  int get recordDuration => operationsController.recordDuration;
  bool get isLoading => dataController.isLoading || publishingController.isLoading;
  bool get isUploading => driveController.isUploading;
  List<UserRecording> get recordings => dataController.recordings;
  List<UserRecording> get publicRecordings => publishingController.publicRecordings;
  Set<String> get uploadingRecordingIds => driveController.uploadingRecordingIds;
  Map<String, String> get uploadErrors => driveController.uploadErrors;
  bool get overlayVisible => uiController.overlayVisible;
  bool get isOverlayMinimized => uiController.isOverlayMinimized;
  String get currentHymnId => uiController.currentHymnId;
  String get currentHymnTitle => uiController.currentHymnTitle;
  bool get playerOverlayVisible => uiController.playerOverlayVisible;
  bool get isPlayerMinimized => uiController.isPlayerMinimized;
  UserRecording? get currentRecording => uiController.currentRecording;

  String get lastError =>
      operationsController.lastError +
      dataController.lastError +
      publishingController.lastError +
      driveController.lastError;

  // Delegated methods for backward compatibility
  Future<void> startRecording(String hymnId) async {
    await operationsController.startRecording(hymnId);
    uiController.showOverlay(hymnId, '');
  }

  Future<UserRecording?> stopRecording(String hymnId, String title) async {
    final recording = await operationsController.stopRecording(hymnId, title);
    uiController.hideOverlay();
    return recording;
  }

  Future<void> pauseRecording() => operationsController.pauseRecording();
  Future<void> resumeRecording() => operationsController.resumeRecording();
  Future<void> cancelRecording() => operationsController.cancelRecording();

  Future<void> updateRecording(UserRecording recording) =>
      dataController.updateRecording(recording);

  Future<void> deleteRecording(UserRecording recording) =>
      dataController.deleteRecording(recording);

  Future<UserRecording?> getRecordingById(String id) =>
      Future.value(dataController.getRecordingById(id));

  Future<void> publishRecording(UserRecording recording) =>
      publishingController.publishRecording(recording);

  Future<void> unpublishRecording(UserRecording recording) =>
      publishingController.unpublishRecording(recording);

  Future<void> toggleRecordingPrivacy(UserRecording recording) =>
      publishingController.toggleRecordingPrivacy(recording);

  List<UserRecording> searchRecordings(String query) =>
      searchRecordingsUseCase(query);

  List<UserRecording> getRecordingsByHymnId(String hymnId) =>
      getRecordingsByHymnIdUseCase(hymnId);

  Future<bool> uploadToDrive(UserRecording recording) =>
      driveController.uploadToDrive(recording);

  Future<void> syncFromDrive({bool force = false}) =>
      driveController.syncFromDrive(force: force);

  bool isUploadingRecording(String recordingId) =>
      driveController.isUploadingRecording(recordingId);

  String? getUploadError(String recordingId) =>
      driveController.getUploadError(recordingId);

  // UI methods
  void showOverlay(String hymnId, String title) =>
      uiController.showOverlay(hymnId, title);

  void hideOverlay() => uiController.hideOverlay();

  void minimizeOverlay() => uiController.minimizeOverlay();

  void maximizeOverlay() => uiController.maximizeOverlay();

  void showPlayerOverlay(UserRecording recording) =>
      uiController.showPlayerOverlay(recording);

  void hidePlayerOverlay() => uiController.hidePlayerOverlay();

  void minimizePlayer() => uiController.minimizePlayer();

  void maximizePlayer() => uiController.maximizePlayer();

  bool shouldShowOverlay() => uiController.shouldShowOverlay();

  void restoreOverlay() => uiController.restoreOverlay();

  // Additional utility methods
  void clearErrors() {
    operationsController.clearError();
    dataController.clearError();
    publishingController.clearError();
    driveController.clearError();
  }

  void refreshData() {
    dataController.refreshData();
    publishingController.refreshPublicRecordings();
  }

  void resetUIState() {
    uiController.resetUIState();
  }
}