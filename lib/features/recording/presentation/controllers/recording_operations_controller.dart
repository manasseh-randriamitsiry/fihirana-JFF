import 'dart:async';
import 'package:get/get.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/domain/usecases/recording_usecases.dart';

/// Controller responsible for basic recording operations
class RecordingOperationsController extends GetxController {
  final StartRecordingUseCase startRecordingUseCase;
  final StopRecordingUseCase stopRecordingUseCase;
  final CancelRecordingUseCase cancelRecordingUseCase;
  final SaveRecordingUseCase saveRecordingUseCase;

  final RxBool _isRecording = false.obs;
  final RxBool _isPaused = false.obs;
  final RxInt _recordDuration = 0.obs;
  final RxString _lastError = ''.obs;

  Timer? _recordingTimer;

  RecordingOperationsController({
    required this.startRecordingUseCase,
    required this.stopRecordingUseCase,
    required this.cancelRecordingUseCase,
    required this.saveRecordingUseCase,
  });

  // Getters
  bool get isRecording => _isRecording.value;
  bool get isPaused => _isPaused.value;
  int get recordDuration => _recordDuration.value;
  String get lastError => _lastError.value;

  @override
  void onClose() {
    _recordingTimer?.cancel();
    super.onClose();
  }

  Future<void> startRecording(String hymnId) async {
    try {
      _lastError.value = '';
      await startRecordingUseCase();
      _isRecording.value = true;
      _startRecordingTimer();
    } catch (e) {
      _lastError.value = 'Failed to start recording: $e';
      rethrow;
    }
  }

  Future<UserRecording?> stopRecording(String hymnId, String title) async {
    try {
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
        return updatedRecording;
      }
      return null;
    } catch (e) {
      _lastError.value = 'Failed to stop recording: $e';
      rethrow;
    }
  }

  Future<void> pauseRecording() async {
    _isPaused.value = true;
    _recordingTimer?.cancel();
  }

  Future<void> resumeRecording() async {
    _isPaused.value = false;
    _startRecordingTimer();
  }

  Future<void> cancelRecording() async {
    try {
      await cancelRecordingUseCase();
      _isRecording.value = false;
      _stopRecordingTimer();
    } catch (e) {
      _lastError.value = 'Failed to cancel recording: $e';
      rethrow;
    }
  }

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

  void clearError() {
    _lastError.value = '';
  }
}