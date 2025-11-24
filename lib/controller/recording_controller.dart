import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../models/user_recording.dart';
import '../services/user_recording_service.dart';
import '../services/google_drive_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingController extends GetxController {
  final UserRecordingService _recordingService = UserRecordingService();
  final GoogleDriveService _driveService = GoogleDriveService();

  // Recording state
  final RxBool isRecording = false.obs;
  final RxBool isPaused = false.obs;
  final RxInt recordDuration = 0.obs;
  Timer? _timer;

  // Playback state
  final AudioPlayer _audioPlayer = AudioPlayer();
  final RxBool isPlaying = false.obs;
  final RxString currentPlayingId = ''.obs;
  final Rx<Duration> currentPosition = Duration.zero.obs;
  final Rx<Duration> totalDuration = Duration.zero.obs;
  final RxDouble playbackSpeed = 1.0.obs;

  // Data
  final RxList<UserRecording> recordings = <UserRecording>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isUploading = false.obs;

  // Drive state
  final RxBool isDriveSignedIn = false.obs;
  final Rxn<String> userEmail = Rxn<String>();
  final RxString guestName = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initServices();
    _loadGuestName();
    _setupAudioPlayerListeners();
  }

  Future<void> _loadGuestName() async {
    final prefs = await SharedPreferences.getInstance();
    guestName.value = prefs.getString('guest_name') ?? '';
  }

  Future<void> setGuestName(String name) async {
    guestName.value = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('guest_name', name);
  }

  @override
  void onClose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.onClose();
  }

  Future<void> _initServices() async {
    await _recordingService.initialize();
    recordings.bindStream(_recordingService.recordingsStream);

    // Check Drive sign-in status silently
    // Note: This might need explicit user action to sign in initially
    // but we can check if we have a cached user
    /*
    try {
      final account = await _driveService.signIn();
      if (account != null) {
        isDriveSignedIn.value = true;
        userEmail.value = account.email;
      }
    } catch (e) {
      // Silent sign-in failed or cancelled
    }
    */
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      if (state.processingState == ProcessingState.completed) {
        isPlaying.value = false;
        currentPlayingId.value = '';
        currentPosition.value = Duration.zero;
      }
    });

    _audioPlayer.positionStream.listen((position) {
      currentPosition.value = position;
    });

    _audioPlayer.durationStream.listen((duration) {
      totalDuration.value = duration ?? Duration.zero;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      recordDuration.value++;
    });
  }

  // Recording Actions
  Future<void> startRecording(String hymnId) async {
    await _recordingService.startRecording(hymnId);
    isRecording.value = true;
    isPaused.value = false;
    recordDuration.value = 0;
    _startTimer();
  }

  Future<UserRecording?> stopRecording(String hymnId, String title) async {
    final filePath = await _recordingService.stopRecording();
    isRecording.value = false;
    isPaused.value = false;
    _timer?.cancel();
    
    if (filePath != null) {
      final recording = await _recordingService.saveRecording(
        filePath: filePath,
        hymnId: hymnId,
        title: title,
        durationSeconds: recordDuration.value,
      );
      return recording;
    }
    return null;
  }

  Future<void> pauseRecording() async {
    await _recordingService.pauseRecording();
    isPaused.value = true;
    _timer?.cancel();
  }

  Future<void> resumeRecording() async {
    await _recordingService.resumeRecording();
    isPaused.value = false;
    _startTimer();
  }

  // Playback Actions
  Future<void> playRecording(UserRecording recording) async {
    try {
      currentPlayingId.value = recording.id;
      await _audioPlayer.setFilePath(recording.filePath);
      await _audioPlayer.play();
    } catch (e) {
      Get.snackbar('Error', 'Failed to play recording');
    }
  }

  Future<void> pausePlayback() async {
    await _audioPlayer.pause();
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    playbackSpeed.value = speed;
    await _audioPlayer.setSpeed(speed);
  }

  // Management Actions
  Future<void> deleteRecording(UserRecording recording) async {
    await _recordingService.deleteRecording(recording.id);
    if (recording.driveFileId != null) {
      // Optionally delete from Drive too, or ask user
      // For now, let's just delete local reference
      // await _driveService.deleteFile(recording.driveFileId!);
    }
  }

  Future<void> updateRecording(UserRecording recording) async {
    await _recordingService.updateRecording(recording);
  }

  Future<void> renameRecording(UserRecording recording, String newTitle) async {
    final updated = recording.copyWith(title: newTitle);
    await updateRecording(updated);

    // If uploaded to Drive, we might want to rename there too, but that requires an extra API call.
    // For now, we just rename locally.
    recordings.refresh();
  }

  Future<String> getStorageUsage() async {
    int totalBytes = 0;
    for (var rec in recordings) {
      try {
        final file = File(rec.filePath);
        if (await file.exists()) {
          totalBytes += await file.length();
        }
      } catch (e) {
        // ignore
      }
    }

    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Drive Actions
  Future<void> signInToDrive() async {
    final account = await _driveService.signIn();
    if (account != null) {
      isDriveSignedIn.value = true;
      userEmail.value = account.email;
    }
  }

  Future<void> signOutFromDrive() async {
    await _driveService.signOut();
    isDriveSignedIn.value = false;
    userEmail.value = null;
  }

  Future<void> uploadToDrive(UserRecording recording) async {
    if (!isDriveSignedIn.value) {
      await signInToDrive();
      if (!isDriveSignedIn.value) return;
    }

    isUploading.value = true;
    try {
      final file = File(recording.filePath);
      if (await file.exists()) {
        final fileId = await _driveService.uploadFile(
          file,
          '${recording.title}.m4a',
          description: 'Hymn: ${recording.hymnId}',
        );

        if (fileId != null) {
          final webLink = await _driveService.getWebViewLink(fileId);
          final updated = recording.copyWith(
            driveFileId: fileId,
            driveWebLink: webLink,
          );
          await _recordingService.updateRecording(updated);
          Get.snackbar('Success', 'Recording uploaded to Drive');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload recording');
    } finally {
      isUploading.value = false;
    }
  }
}
