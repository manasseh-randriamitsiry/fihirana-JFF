import 'package:get/get.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';

/// Controller responsible for UI state management (overlays, dialogs, etc.)
class RecordingUIController extends GetxController {
  final RxBool _overlayVisible = false.obs;
  final RxBool _isOverlayMinimized = false.obs;
  final RxString _currentHymnId = ''.obs;
  final RxString _currentHymnTitle = ''.obs;

  final RxBool _playerOverlayVisible = false.obs;
  final RxBool _isPlayerMinimized = false.obs;
  final Rxn<UserRecording> _currentRecording = Rxn<UserRecording>();

  // Getters
  bool get overlayVisible => _overlayVisible.value;
  bool get isOverlayMinimized => _isOverlayMinimized.value;
  String get currentHymnId => _currentHymnId.value;
  String get currentHymnTitle => _currentHymnTitle.value;
  bool get playerOverlayVisible => _playerOverlayVisible.value;
  bool get isPlayerMinimized => _isPlayerMinimized.value;
  UserRecording? get currentRecording => _currentRecording.value;

  // Overlay methods
  void showOverlay(String hymnId, String title) {
    _currentHymnId.value = hymnId;
    _currentHymnTitle.value = title;
    _overlayVisible.value = true;
    _isOverlayMinimized.value = false;
  }

  void hideOverlay() {
    _overlayVisible.value = false;
    _isOverlayMinimized.value = false;
    _currentHymnId.value = '';
    _currentHymnTitle.value = '';
  }

  void minimizeOverlay() {
    _isOverlayMinimized.value = true;
  }

  void maximizeOverlay() {
    _isOverlayMinimized.value = false;
  }

  bool shouldShowOverlay() {
    return _overlayVisible.value && !_isOverlayMinimized.value;
  }

  void restoreOverlay() {
    _isOverlayMinimized.value = false;
  }

  // Player overlay methods
  void showPlayerOverlay(UserRecording recording) {
    _currentRecording.value = recording;
    _playerOverlayVisible.value = true;
    _isPlayerMinimized.value = false;
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

  void restorePlayer() {
    _isPlayerMinimized.value = false;
  }

  // Utility methods
  void resetUIState() {
    hideOverlay();
    hidePlayerOverlay();
  }
}