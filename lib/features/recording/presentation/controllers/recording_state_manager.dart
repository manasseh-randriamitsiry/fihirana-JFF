import 'dart:async';
import 'package:get/get.dart';

/// Manages recording state and timers
class RecordingStateManager extends GetxController {
  // Recording state
  final RxBool isRecording = false.obs;
  final RxBool isPaused = false.obs;
  final RxInt recordDuration = 0.obs;
  Timer? _timer;

  // Overlay state for recording UI
  final RxBool isOverlayMinimized = false.obs;
  final RxString currentHymnId = ''.obs;
  final RxString currentHymnTitle = ''.obs;
  final RxBool overlayVisible = false.obs;

  // Player overlay state
  final RxBool isPlayerOverlayVisible = false.obs;
  final RxBool isPlayerMinimized = false.obs;

  // Data loading state
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;

  // Error tracking
  final RxString lastError = ''.obs;

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // Timer management
  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      recordDuration.value++;
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }

  void resetTimer() {
    recordDuration.value = 0;
  }

  // Recording overlay management
  void showOverlay(String hymnId, String hymnTitle) {
    currentHymnId.value = hymnId;
    currentHymnTitle.value = hymnTitle;
    overlayVisible.value = true;
    isOverlayMinimized.value = false;
  }

  void minimizeOverlay() {
    isOverlayMinimized.value = true;
  }

  void restoreOverlay() {
    isOverlayMinimized.value = false;
  }

  void hideOverlay() {
    overlayVisible.value = false;
    isOverlayMinimized.value = false;
    currentHymnId.value = '';
    currentHymnTitle.value = '';
  }

  bool shouldShowOverlay() {
    return overlayVisible.value;
  }

  // Player overlay management
  void showPlayerOverlay() {
    isPlayerOverlayVisible.value = true;
    isPlayerMinimized.value = false;
  }

  void minimizePlayer() {
    isPlayerMinimized.value = true;
  }

  void restorePlayer() {
    isPlayerMinimized.value = false;
  }

  void hidePlayerOverlay() {
    isPlayerOverlayVisible.value = false;
    isPlayerMinimized.value = false;
  }

  bool shouldShowPlayerOverlay() {
    return isPlayerOverlayVisible.value;
  }

  // State reset methods
  void resetRecordingState() {
    isRecording.value = false;
    isPaused.value = false;
    resetTimer();
    stopTimer();
  }
}
