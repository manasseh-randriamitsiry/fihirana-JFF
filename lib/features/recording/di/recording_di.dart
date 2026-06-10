import 'package:get/get.dart';
import 'package:fihirana/features/recording/data/repositories/recording_repository_impl.dart';
import 'package:fihirana/features/recording/domain/repositories/recording_repository.dart';
import 'package:fihirana/features/recording/domain/usecases/recording_usecases.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/features/recording/data/services/recording_service.dart';

/// Dependency injection for recording feature
class RecordingDI {
  static const String _recordingRepositoryTag = 'recordingRepository';
  static const String _recordingControllerTag = 'recordingController';

  /// Initialize recording dependencies
  static void initialize() {
    // Service
    Get.lazyPut<RecordingService>(() => RecordingService());

    // Repository - register globally (without tag) for backward compatibility
    Get.lazyPut<RecordingRepository>(() => RecordingRepositoryImpl());

    // Repository - also register with tag for new code
    Get.lazyPut<RecordingRepository>(
      () => Get.find<RecordingRepository>(), // Reuse the global instance
      tag: _recordingRepositoryTag,
    );

    // Use cases - Recording Management
    Get.put<StartRecordingUseCase>(
      StartRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.put<StopRecordingUseCase>(
      StopRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.put<CancelRecordingUseCase>(
      CancelRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.put<LoadRecordingsUseCase>(
      LoadRecordingsUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.put<SaveRecordingUseCase>(
      SaveRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.put<UpdateRecordingUseCase>(
      UpdateRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.put<DeleteRecordingUseCase>(
      DeleteRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.put<GetRecordingByIdUseCase>(
      GetRecordingByIdUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    // Use cases - Public Recordings
    Get.put<LoadPublicRecordingsUseCase>(
      LoadPublicRecordingsUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.put<PublishRecordingUseCase>(
      PublishRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.put<UnpublishRecordingUseCase>(
      UnpublishRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.put<ToggleRecordingPrivacyUseCase>(
      ToggleRecordingPrivacyUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    // Use cases - Search and Filter
    Get.put<SearchRecordingsUseCase>(
      SearchRecordingsUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.put<GetRecordingsByHymnIdUseCase>(
      GetRecordingsByHymnIdUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    // Use cases - Drive Integration
    Get.put<UploadToGoogleDriveUseCase>(
      UploadToGoogleDriveUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.put<SyncFromDriveUseCase>(
      SyncFromDriveUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    // Use cases - Deleted Recordings
    Get.put<LoadDeletedRecordingsUseCase>(
      LoadDeletedRecordingsUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.put<RestoreRecordingUseCase>(
      RestoreRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.put<PermanentlyDeleteRecordingUseCase>(
      PermanentlyDeleteRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.put<PermanentlyDeleteMultipleRecordingsUseCase>(
      PermanentlyDeleteMultipleRecordingsUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    // Controller (register both with and without tag for compatibility)
    final controller = RecordingController(
      repository: Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      startRecordingUseCase: Get.find<StartRecordingUseCase>(),
      stopRecordingUseCase: Get.find<StopRecordingUseCase>(),
      cancelRecordingUseCase: Get.find<CancelRecordingUseCase>(),
      loadRecordingsUseCase: Get.find<LoadRecordingsUseCase>(),
      saveRecordingUseCase: Get.find<SaveRecordingUseCase>(),
      updateRecordingUseCase: Get.find<UpdateRecordingUseCase>(),
      deleteRecordingUseCase: Get.find<DeleteRecordingUseCase>(),
      getRecordingByIdUseCase: Get.find<GetRecordingByIdUseCase>(),
      loadPublicRecordingsUseCase: Get.find<LoadPublicRecordingsUseCase>(),
      publishRecordingUseCase: Get.find<PublishRecordingUseCase>(),
      unpublishRecordingUseCase: Get.find<UnpublishRecordingUseCase>(),
      toggleRecordingPrivacyUseCase: Get.find<ToggleRecordingPrivacyUseCase>(),
      searchRecordingsUseCase: Get.find<SearchRecordingsUseCase>(),
      getRecordingsByHymnIdUseCase: Get.find<GetRecordingsByHymnIdUseCase>(),
      uploadToGoogleDriveUseCase: Get.find<UploadToGoogleDriveUseCase>(),
      syncFromDriveUseCase: Get.find<SyncFromDriveUseCase>(),
      loadDeletedRecordingsUseCase: Get.find<LoadDeletedRecordingsUseCase>(),
      restoreRecordingUseCase: Get.find<RestoreRecordingUseCase>(),
      permanentlyDeleteRecordingUseCase:
          Get.find<PermanentlyDeleteRecordingUseCase>(),
      permanentlyDeleteMultipleRecordingsUseCase:
          Get.find<PermanentlyDeleteMultipleRecordingsUseCase>(),
    );

    Get.put<RecordingController>(
      controller,
      tag: _recordingControllerTag,
    );

    // Also register without tag for backward compatibility
    Get.put<RecordingController>(
      controller,
    );
  }

  /// Get recording controller
  static RecordingController get recordingController {
    try {
      return Get.find<RecordingController>(tag: _recordingControllerTag);
    } catch (e) {
      // Fallback to untagged version
      return Get.find<RecordingController>();
    }
  }

  /// Get recording repository
  static RecordingRepository get recordingRepository {
    return Get.find<RecordingRepository>(tag: _recordingRepositoryTag);
  }

  /// Dispose recording dependencies
  static void dispose() {
    if (Get.isRegistered<RecordingController>(tag: _recordingControllerTag)) {
      Get.delete<RecordingController>(tag: _recordingControllerTag);
    }
    if (Get.isRegistered<RecordingController>()) {
      Get.delete<RecordingController>(); // Also delete untagged version
    }
    if (Get.isRegistered<PermanentlyDeleteRecordingUseCase>())
      Get.delete<PermanentlyDeleteRecordingUseCase>();
    if (Get.isRegistered<RestoreRecordingUseCase>())
      Get.delete<RestoreRecordingUseCase>();
    if (Get.isRegistered<LoadDeletedRecordingsUseCase>())
      Get.delete<LoadDeletedRecordingsUseCase>();
    if (Get.isRegistered<SyncFromDriveUseCase>())
      Get.delete<SyncFromDriveUseCase>();
    if (Get.isRegistered<UploadToGoogleDriveUseCase>())
      Get.delete<UploadToGoogleDriveUseCase>();
    if (Get.isRegistered<GetRecordingsByHymnIdUseCase>())
      Get.delete<GetRecordingsByHymnIdUseCase>();
    if (Get.isRegistered<SearchRecordingsUseCase>())
      Get.delete<SearchRecordingsUseCase>();
    if (Get.isRegistered<ToggleRecordingPrivacyUseCase>())
      Get.delete<ToggleRecordingPrivacyUseCase>();
    if (Get.isRegistered<UnpublishRecordingUseCase>())
      Get.delete<UnpublishRecordingUseCase>();
    if (Get.isRegistered<PublishRecordingUseCase>())
      Get.delete<PublishRecordingUseCase>();
    if (Get.isRegistered<LoadPublicRecordingsUseCase>())
      Get.delete<LoadPublicRecordingsUseCase>();
    if (Get.isRegistered<GetRecordingByIdUseCase>())
      Get.delete<GetRecordingByIdUseCase>();
    if (Get.isRegistered<DeleteRecordingUseCase>())
      Get.delete<DeleteRecordingUseCase>();
    if (Get.isRegistered<UpdateRecordingUseCase>())
      Get.delete<UpdateRecordingUseCase>();
    if (Get.isRegistered<SaveRecordingUseCase>())
      Get.delete<SaveRecordingUseCase>();
    if (Get.isRegistered<LoadRecordingsUseCase>())
      Get.delete<LoadRecordingsUseCase>();
    if (Get.isRegistered<CancelRecordingUseCase>())
      Get.delete<CancelRecordingUseCase>();
    if (Get.isRegistered<StopRecordingUseCase>())
      Get.delete<StopRecordingUseCase>();
    if (Get.isRegistered<StartRecordingUseCase>())
      Get.delete<StartRecordingUseCase>();
    if (Get.isRegistered<RecordingRepository>(tag: _recordingRepositoryTag))
      Get.delete<RecordingRepository>(tag: _recordingRepositoryTag);
  }

  /// Reset recording dependencies (for testing)
  static void reset() {
    dispose();
    initialize();
  }
}
