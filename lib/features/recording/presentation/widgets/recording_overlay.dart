import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'recording_fab.dart';
import 'recording_card.dart';
import 'recording_save_dialog.dart';
import 'recording_upload_dialog.dart';
import 'recording_close_confirmation.dart';

enum RecordingOverlayState {
  idle,
  recording,
  saving,
  uploading,
}

class RecordingOverlay extends StatefulWidget {
  final String hymnId;
  final String hymnTitle;
  final VoidCallback onClose;
  final VoidCallback? onMinimize;

  const RecordingOverlay({
    super.key,
    required this.hymnId,
    required this.hymnTitle,
    required this.onClose,
    this.onMinimize,
  });

  @override
  State<RecordingOverlay> createState() => _RecordingOverlayState();
}

class _RecordingOverlayState extends State<RecordingOverlay>
    with TickerProviderStateMixin {
  late final RecordingController _controller;
  late final ColorController _colorController;

  late AnimationController _countdownController;
  late AnimationController _pulseController;
  int _countdown = 3;
  bool _isCountingDown = false;
  RecordingOverlayState _state = RecordingOverlayState.idle;
  bool _isExpanded = false; // Default to collapsed (FAB)

  final TextEditingController _nameController = TextEditingController();
  UserRecording? _currentRecording;

  @override
  void initState() {
    super.initState();

    // Cache controller references for faster access
    _controller = Get.find<RecordingController>();
    _colorController = Get.find<ColorController>();

    // Initialize animation controllers
    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Defer non-critical initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start pulse animation after first frame
      _pulseController.repeat(reverse: true);

      // Generate recording name asynchronously
      _generateRecordingName();

      // Update controller state
      _controller.showOverlay(widget.hymnId, widget.hymnTitle);
    });
  }

  void _generateRecordingName() {
    if (!mounted) return;

    // Only generate name if controller is empty (to avoid overwriting user input)
    if (_nameController.text.isEmpty) {
      final now = DateTime.now();
      final timestamp =
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      _nameController.text = '${widget.hymnTitle} - $timestamp';
    }
  }

  @override
  void dispose() {
    _countdownController.dispose();
    _pulseController.dispose();
    // Dispose text controller last to avoid issues
    _nameController.dispose();
    // Only hide overlay if not minimized (recording continues in background)
    if (!_controller.isOverlayMinimized.value) {
      _controller.hideOverlay();
    }
    super.dispose();
  }

  void _startCountdown() async {
    setState(() {
      _isExpanded = true; // Expand to show countdown
      _isCountingDown = true;
      _countdown = 3;
    });

    for (int i = 3; i > 0; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      _countdownController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    if (!mounted) return;
    setState(() => _isCountingDown = false);
    try {
      await _controller.startRecording(widget.hymnId);
      // Check if recording actually started
      if (!_controller.isRecording.value) {
        throw Exception('Recording failed to start');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExpanded = false;
          _isCountingDown = false;
        });
        Get.snackbar(
          'Recording Error',
          'Failed to start recording: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
      return;
    }
  }

  void _stopRecording() async {
    final recording =
        await _controller.stopRecording(widget.hymnId, widget.hymnTitle);

    if (recording != null) {
      // Store's current recording for later reference
      _currentRecording = recording;
      setState(() => _state = RecordingOverlayState.saving);
    } else {
      // Show error message to user
      Get.snackbar(
        'Error',
        'Failed to save recording. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      // Reset overlay state
      setState(() {
        _state = RecordingOverlayState.idle;
        _isExpanded = false;
      });
    }
  }

  void _saveRecording(bool uploadToDrive, bool isPublic) async {
    // Check if controller is still valid before accessing text
    if (!mounted || !_nameController.text.isNotEmpty) {
      Get.snackbar('Error', 'Please enter a name for the recording');
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Error', 'Please enter a name for the recording');
      return;
    }

    // Update recording name
    if (_currentRecording != null) {
      // Update recording name
      await _controller.renameRecording(_currentRecording!, name);

      if (uploadToDrive || isPublic) {
        // Transition to uploading state
        setState(() => _state = RecordingOverlayState.uploading);
        // Start upload
        _startUpload(_currentRecording!, isPublic: isPublic);
      } else {
        // Auto-close overlay when save is complete
        if (mounted) {
          _controller.hideOverlay();
          widget.onClose();
        }
      }
    } else {
      // Auto-close overlay even if no recording
      _controller.hideOverlay();
      widget.onClose();
    }
  }

  void _startUpload(UserRecording recording, {bool isPublic = false}) async {
    try {
      // Trigger upload
      await _controller.uploadToDrive(recording);

      // If marked as public, publish to Firestore after upload
      if (isPublic) {
        // Get the updated recording with Drive info
        final updatedRecording = _controller.recordings
            .firstWhereOrNull((r) => r.id == recording.id);
        if (updatedRecording != null) {
          await _controller.publishRecording(updatedRecording);
        }
      }

      // Close overlay on success
      if (mounted) {
        _controller.hideOverlay();
        widget.onClose();
      }
    } catch (e) {
      // Show error and stay in uploading state or go back to saving
      Get.snackbar(
        "Échec de l'envoi",
        "Échec de l'envoi de l'enregistrement : $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      // Go back to saving state so user can try again
      if (mounted) {
        setState(() => _state = RecordingOverlayState.saving);
      }
    }
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
  }

  void _showCloseConfirmation() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => RecordingCloseConfirmation(
        controller: _controller,
        colorController: _colorController,
        l10n: l10n,
        onDiscard: () async {
          Get.back();
          await _controller.stopRecording(widget.hymnId, widget.hymnTitle);
          widget.onClose();
          Get.snackbar(l10n.discard, l10n.recordingNotSaved);
        },
        onSave: () {
          Get.back();
          _stopRecording();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Modal Dimmer (only for saving/uploading)
        if (_state == RecordingOverlayState.saving ||
            _state == RecordingOverlayState.uploading)
          GestureDetector(
            onTap: () {
              // Prevent closing by tapping outside for now, or implement specific behavior
            },
            child: Container(
              color: Colors.black54,
            ),
          ),

        // Content
        if (_state == RecordingOverlayState.saving)
          Center(
            child: _buildSaveDialog(l10n),
          )
        else if (_state == RecordingOverlayState.uploading)
          Center(
            child: _buildUploadDialog(l10n),
          )
        else
          Positioned(
            bottom: 20,
            right: 20,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.bottomRight,
              child: _isExpanded ? _buildExpandedCard(l10n) : _buildFab(l10n),
            ),
          ),
      ],
    );
  }

  Widget _buildFab(AppLocalizations l10n) {
    return RecordingFab(
      controller: _controller,
      colorController: _colorController,
      pulseController: _pulseController,
      onTap: _toggleExpand,
    );
  }

  Widget _buildExpandedCard(AppLocalizations l10n) {
    return RecordingCard(
      controller: _controller,
      colorController: _colorController,
      l10n: l10n,
      hymnTitle: widget.hymnTitle,
      hymnId: widget.hymnId,
      isCountingDown: _isCountingDown,
      countdown: _countdown,
      countdownController: _countdownController,
      pulseController: _pulseController,
      onStartRecording: _startCountdown,
      onStopRecording: _stopRecording,
      onClose: () => _showCloseConfirmation(),
      onMinimize: _toggleExpand,
    );
  }

  Widget _buildSaveDialog(AppLocalizations l10n) {
    return RecordingSaveDialog(
      controller: _controller,
      colorController: _colorController,
      currentRecording: _currentRecording,
      nameController: _nameController,
      onSave: _saveRecording,
      onDiscard: () {
        widget.onClose();
      },
    );
  }

  Widget _buildUploadDialog(AppLocalizations l10n) {
    if (_currentRecording == null) return const SizedBox.shrink();

    return RecordingUploadDialog(
      controller: _controller,
      colorController: _colorController,
      recording: _currentRecording!,
      onDone: () {
        _controller.hideOverlay();
        widget.onClose();
      },
    );
  }
}
