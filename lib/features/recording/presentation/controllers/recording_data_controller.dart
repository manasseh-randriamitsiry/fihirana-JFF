import 'package:get/get.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/domain/usecases/recording_usecases.dart';

/// Controller responsible for recording data management (CRUD operations)
class RecordingDataController extends GetxController {
  final LoadRecordingsUseCase loadRecordingsUseCase;
  final UpdateRecordingUseCase updateRecordingUseCase;
  final DeleteRecordingUseCase deleteRecordingUseCase;
  final GetRecordingByIdUseCase getRecordingByIdUseCase;
  final LoadDeletedRecordingsUseCase loadDeletedRecordingsUseCase;
  final RestoreRecordingUseCase restoreRecordingUseCase;
  final PermanentlyDeleteRecordingUseCase permanentlyDeleteRecordingUseCase;

  final RxBool _isLoading = false.obs;
  final RxString _lastError = ''.obs;
  final RxList<UserRecording> _recordings = <UserRecording>[].obs;
  final RxList<UserRecording> _deletedRecordings = <UserRecording>[].obs;

  RecordingDataController({
    required this.loadRecordingsUseCase,
    required this.updateRecordingUseCase,
    required this.deleteRecordingUseCase,
    required this.getRecordingByIdUseCase,
    required this.loadDeletedRecordingsUseCase,
    required this.restoreRecordingUseCase,
    required this.permanentlyDeleteRecordingUseCase,
  });

  // Getters
  bool get isLoading => _isLoading.value;
  String get lastError => _lastError.value;
  List<UserRecording> get recordings => _recordings;
  List<UserRecording> get deletedRecordings => _deletedRecordings;

  @override
  void onInit() {
    super.onInit();
    loadRecordings();
    loadDeletedRecordings();
  }

  Future<void> loadRecordings() async {
    try {
      _isLoading.value = true;
      _lastError.value = '';
      await loadRecordingsUseCase();
    } catch (e) {
      _lastError.value = 'Failed to load recordings: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> updateRecording(UserRecording recording) async {
    try {
      _isLoading.value = true;
      _lastError.value = '';
      await updateRecordingUseCase(recording);

      // Update local list
      final index = _recordings.indexWhere((r) => r.id == recording.id);
      if (index != -1) {
        _recordings[index] = recording;
      }
    } catch (e) {
      _lastError.value = 'Failed to update recording: $e';
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteRecording(UserRecording recording) async {
    try {
      _isLoading.value = true;
      _lastError.value = '';
      await deleteRecordingUseCase(recording.id);

      // Remove from local list
      _recordings.removeWhere((r) => r.id == recording.id);
    } catch (e) {
      _lastError.value = 'Failed to delete recording: $e';
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  UserRecording? getRecordingById(String id) {
    try {
      _lastError.value = '';
      return getRecordingByIdUseCase(id);
    } catch (e) {
      _lastError.value = 'Failed to get recording: $e';
      return null;
    }
  }

  Future<void> loadDeletedRecordings() async {
    try {
      _lastError.value = '';
      await loadDeletedRecordingsUseCase();
    } catch (e) {
      _lastError.value = 'Failed to load deleted recordings: $e';
    }
  }

  Future<void> restoreRecording(UserRecording deletedRecording) async {
    try {
      _isLoading.value = true;
      _lastError.value = '';
      await restoreRecordingUseCase(deletedRecording.id);

      // Remove from deleted and add to active
      _deletedRecordings.removeWhere((r) => r.id == deletedRecording.id);
      _recordings.add(deletedRecording);

      // Reload data to ensure consistency
      await loadRecordings();
      await loadDeletedRecordings();
    } catch (e) {
      _lastError.value = 'Failed to restore recording: $e';
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> permanentlyDeleteRecording(UserRecording deletedRecording) async {
    try {
      _isLoading.value = true;
      _lastError.value = '';
      await permanentlyDeleteRecordingUseCase(deletedRecording.id);

      // Remove from deleted list
      _deletedRecordings.removeWhere((r) => r.id == deletedRecording.id);
    } catch (e) {
      _lastError.value = 'Failed to permanently delete recording: $e';
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  void clearError() {
    _lastError.value = '';
  }

  void refreshData() {
    loadRecordings();
    loadDeletedRecordings();
  }
}