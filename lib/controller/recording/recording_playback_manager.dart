import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/user_recording.dart';
import '../../models/hymn.dart';
import '../../services/audio/audio_service.dart';
import '../../services/audio/user_recording_service.dart';
import '../../widgets/player/compact_audio_player_widget.dart';
import '../../l10n/app_localizations.dart';
import 'recording_state_manager.dart';

/// Manages playback functionality
class RecordingPlaybackManager extends GetxController {
  final RecordingStateManager _stateManager;
  final Rxn<UserRecording> currentRecording = Rxn<UserRecording>();

  RecordingPlaybackManager({
    required RecordingStateManager stateManager,
  }) : _stateManager = stateManager;

  // Playback Actions
  Future<void> playRecording(UserRecording recording) async {
    try {
      await AudioService.instance.playRecording(recording);
    } catch (e) {
      Get.snackbar('Error', 'Failed to play recording: $e');
    }
  }

  Future<void> pausePlayback() async {
    await AudioService.instance.pause();
  }

  Future<void> seekTo(Duration position) async {
    await AudioService.instance.seekTo(position);
  }

Future<void> setPlaybackSpeed(double speed) async {
    await AudioService.instance.player.setSpeed(speed);
  }

  /// Refresh public URLs for all recordings
  Future<void> refreshPublicUrls() async {
    try {
      final recordingService = UserRecordingService();
      await recordingService.refreshPublicUrls();
      Get.snackbar('Success', 'Public URLs refreshed successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to refresh URLs: $e');
    }
  }

  // Player UI management
  void showPlayer(UserRecording recording,
      {required bool isRecording, required VoidCallback onStopRecording}) {
    if (isRecording) {
      _showStopRecordingDialog(recording, onStopRecording);
      return;
    }

    if (_stateManager.overlayVisible.value) {
      _stateManager.hideOverlay();
    }

    _proceedWithPlayback(recording);
  }

  void hidePlayer() {
    _stateManager.hidePlayerOverlay();
    currentRecording.value = null;
    pausePlayback();
  }

  void minimizePlayer() {
    _stateManager.minimizePlayer();
  }

  void restorePlayer() {
    _stateManager.restorePlayer();
  }

  bool shouldShowPlayerOverlay() {
    return _stateManager.shouldShowPlayerOverlay();
  }

  void _showStopRecordingDialog(
      UserRecording recording, VoidCallback onStopRecording) {
    final l10n = AppLocalizations.of(Get.context!);
    Get.dialog(
      AlertDialog(
        title: Text(l10n!.recordingInProgressDialog),
        content: Text(l10n.pleaseStopRecordingBeforePlaying),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              onStopRecording();
              _stateManager.hideOverlay();
              _proceedWithPlayback(recording);
            },
            child: Text(l10n.stopAndPlay),
          ),
        ],
      ),
    );
  }

  void _proceedWithPlayback(UserRecording recording) {
    final hymn = Hymn(
      id: recording.id,
      hymnNumber: recording.hymnId,
      title: recording.title,
      verses: [],
      createdAt: recording.createdAt,
      createdBy: 'User',
    );

    _showCompactAudioPlayer(hymn, recording);
    playRecording(recording);
  }

  void _showCompactAudioPlayer(Hymn hymn, UserRecording recording) {
    Get.bottomSheet(
      CompactAudioPlayerWidget(
        hymn: hymn,
        playlist: [hymn],
        onClose: () => Get.back(),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
    );
  }
}
