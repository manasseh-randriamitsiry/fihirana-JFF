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
    Get.lazyPut<StartRecordingUseCase>(
      () => StartRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.lazyPut<StopRecordingUseCase>(
      () => StopRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.lazyPut<CancelRecordingUseCase>(
      () => CancelRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.lazyPut<LoadRecordingsUseCase>(
      () => LoadRecordingsUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.lazyPut<SaveRecordingUseCase>(
      () => SaveRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.lazyPut<UpdateRecordingUseCase>(
      () => UpdateRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.lazyPut<DeleteRecordingUseCase>(
      () => DeleteRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.lazyPut<GetRecordingByIdUseCase>(
      () => GetRecordingByIdUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    // Use cases - Public Recordings
    Get.lazyPut<LoadPublicRecordingsUseCase>(
      () => LoadPublicRecordingsUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.lazyPut<PublishRecordingUseCase>(
      () => PublishRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.lazyPut<UnpublishRecordingUseCase>(
      () => UnpublishRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.lazyPut<ToggleRecordingPrivacyUseCase>(
      () => ToggleRecordingPrivacyUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    // Use cases - Search and Filter
    Get.lazyPut<SearchRecordingsUseCase>(
      () => SearchRecordingsUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.lazyPut<GetRecordingsByHymnIdUseCase>(
      () => GetRecordingsByHymnIdUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    // Use cases - Drive Integration
    Get.lazyPut<UploadToGoogleDriveUseCase>(
      () => UploadToGoogleDriveUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.lazyPut<SyncFromDriveUseCase>(
      () => SyncFromDriveUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    // Use cases - Deleted Recordings
    Get.lazyPut<LoadDeletedRecordingsUseCase>(
      () => LoadDeletedRecordingsUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.lazyPut<RestoreRecordingUseCase>(
      () => RestoreRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    Get.lazyPut<PermanentlyDeleteRecordingUseCase>(
      () => PermanentlyDeleteRecordingUseCase(
        Get.find<RecordingRepository>(tag: _recordingRepositoryTag),
      ),
    );

    // Controller (register both with and without tag for compatibility)
    final controller = RecordingController(
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
      toggleRecordingPrivacyUseCase:
          Get.find<ToggleRecordingPrivacyUseCase>(),
      searchRecordingsUseCase: Get.find<SearchRecordingsUseCase>(),
      getRecordingsByHymnIdUseCase: Get.find<GetRecordingsByHymnIdUseCase>(),
      uploadToGoogleDriveUseCase: Get.find<UploadToGoogleDriveUseCase>(),
      syncFromDriveUseCase: Get.find<SyncFromDriveUseCase>(),
      loadDeletedRecordingsUseCase: Get.find<LoadDeletedRecordingsUseCase>(),
      restoreRecordingUseCase: Get.find<RestoreRecordingUseCase>(),
      permanentlyDeleteRecordingUseCase:
          Get.find<PermanentlyDeleteRecordingUseCase>(),
    );

    Get.lazyPut<RecordingController>(
      () => controller,
      tag: _recordingControllerTag,
    );

    // Also register without tag for backward compatibility
    Get.lazyPut<RecordingController>(
      () => controller,
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
    Get.delete<RecordingController>(tag: _recordingControllerTag);
    Get.delete<RecordingController>(); // Also delete untagged version
    Get.delete<PermanentlyDeleteRecordingUseCase>();
    Get.delete<RestoreRecordingUseCase>();
    Get.delete<LoadDeletedRecordingsUseCase>();
    Get.delete<SyncFromDriveUseCase>();
    Get.delete<UploadToGoogleDriveUseCase>();
    Get.delete<GetRecordingsByHymnIdUseCase>();
    Get.delete<SearchRecordingsUseCase>();
    Get.delete<ToggleRecordingPrivacyUseCase>();
    Get.delete<UnpublishRecordingUseCase>();
    Get.delete<PublishRecordingUseCase>();
    Get.delete<LoadPublicRecordingsUseCase>();
    Get.delete<GetRecordingByIdUseCase>();
    Get.delete<DeleteRecordingUseCase>();
    Get.delete<UpdateRecordingUseCase>();
    Get.delete<SaveRecordingUseCase>();
    Get.delete<LoadRecordingsUseCase>();
    Get.delete<CancelRecordingUseCase>();
    Get.delete<StopRecordingUseCase>();
    Get.delete<StartRecordingUseCase>();
    Get.delete<RecordingRepository>(tag: _recordingRepositoryTag);
  }

  /// Reset recording dependencies (for testing)
  static void reset() {
    dispose();
    initialize();
  }
}
