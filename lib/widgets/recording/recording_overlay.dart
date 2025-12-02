import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controller/recording_controller.dart';
import '../../controller/color_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_recording.dart';

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
  bool _showSaveDialog = false;
  bool _isExpanded = false; // Default to collapsed (FAB)

  final TextEditingController _nameController = TextEditingController();
  bool _uploadToDrive = false;
  bool _isPublic = false;
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
    
    final now = DateTime.now();
    final timestamp =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _nameController.text = '${widget.hymnTitle} - $timestamp';
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
    await _controller.startRecording(widget.hymnId);
  }

  void _stopRecording() async {
    if (kDebugMode)
      print(
          'RecordingOverlay: _stopRecording called for hymnId: ${widget.hymnId}');

    final recording =
        await _controller.stopRecording(widget.hymnId, widget.hymnTitle);

    if (kDebugMode)
      print('RecordingOverlay: Recording returned from controller: $recording');

    if (recording != null) {
      // Store's current recording for later reference
      _currentRecording = recording;
      setState(() => _showSaveDialog = true);
      if (kDebugMode) print('RecordingOverlay: Save dialog should show now');

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        await Get.dialog(
          _buildSaveDialog(l10n),
          barrierDismissible: false,
        );
      }
    } else {
      if (kDebugMode)
        print(
            'RecordingOverlay: No recording returned, cannot show save dialog');
      // Show error message to user
      Get.snackbar(
        'Error',
        'Failed to save recording. Please try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

void _saveRecording() async {
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
      // Update the recording with the user's custom name
      await _controller.renameRecording(_currentRecording!, name);

      if (_uploadToDrive) {
        // Close save dialog
        Get.back();
        // Show upload progress in dialog
        _showUploadProgressDialog(_currentRecording!, isPublic: _isPublic);
      } else if (_isPublic) {
        // Close save dialog
        Get.back();
        // If marked as public but not uploading to Drive, we need to upload it
        _showUploadProgressDialog(_currentRecording!, isPublic: true);
      } else {
        // Auto-close overlay when save is complete
        if (mounted) {
          Get.back();
          _controller.hideOverlay();
          widget.onClose();
        }
      }
    } else {
      // Auto-close overlay even if no recording
      if (mounted) {
        Get.back();
      }
      _controller.hideOverlay();
      widget.onClose();
    }
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showCloseConfirmation() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _colorController.backgroundColor.value,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.stop_circle, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Text(
              'Stop Recording?',
              style: TextStyle(
                color: _colorController.textColor.value,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What would you like to do with this recording?',
              style: TextStyle(
                color: _colorController.textColor.value,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    _colorController.primaryColor.value.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _colorController.primaryColor.value
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: _colorController.primaryColor.value,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_controller.recordDuration.value),
                    style: TextStyle(
                      color: _colorController.textColor.value,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: _colorController.textColor.value),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _controller.stopRecording(widget.hymnId, widget.hymnTitle);
              widget.onClose();
              Get.snackbar(l10n.discard, l10n.recordingNotSaved);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(l10n.discard),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _stopRecording();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorController.primaryColor.value,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.saveRecording),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // If showing save dialog, hide the overlay UI (FAB/Card)
    if (_showSaveDialog) {
      return const SizedBox.shrink();
    }

    // Otherwise, position at bottom right
    return Positioned(
      bottom: 20,
      right: 20,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: Alignment.bottomRight,
        child: _isExpanded ? _buildExpandedCard(l10n) : _buildFab(l10n),
      ),
    );
  }

  Widget _buildFab(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _toggleExpand,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _colorController.primaryColor.value,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_controller.isRecording.value)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.3),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),
            Icon(
              _controller.isRecording.value ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
  }

  Widget _buildExpandedCard(AppLocalizations l10n) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colorController.backgroundColor.value,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: _colorController.primaryColor.value.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.hymnTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _colorController.textColor.value,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Hira ${widget.hymnId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _colorController.textColor.value
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (_controller.isRecording.value)
                IconButton(
                  icon: Icon(Icons.close,
                      color: _colorController.textColor.value),
                  onPressed: () {
                    _showCloseConfirmation();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.keyboard_arrow_down,
                    color: _colorController.textColor.value),
                onPressed: _toggleExpand,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Content
          if (_isCountingDown)
            SizedBox(
              height: 100,
              child: _buildCountdown(),
            )
          else
            Column(
              children: [
                // Waveform placeholder or visualizer
                SizedBox(
                  height: 40,
                  child: Obx(() => _buildCompactWaveform()),
                ),

                const SizedBox(height: 12),

                // Timer
                Obx(() => Text(
                      _formatDuration(_controller.recordDuration.value),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: _colorController.primaryColor.value,
                      ),
                    )),

                const SizedBox(height: 16),

                // Controls
                Obx(() => _buildCompactControls()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    return Center(
      child: AnimatedBuilder(
        animation: _countdownController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_countdownController.value * 0.3),
            child: Opacity(
              opacity: 1.0 - _countdownController.value,
              child: Text(
                _countdown.toString(),
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: _colorController.primaryColor.value,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactWaveform() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(15, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 30)),
          width: 4,
          height: _controller.isRecording.value ? 10 + (index % 4) * 8.0 : 10,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: _controller.isRecording.value
                ? _colorController.primaryColor.value
                : _colorController.primaryColor.value.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        )
            .animate(
              onPlay: (controller) => _controller.isRecording.value
                  ? controller.repeat(reverse: true)
                  : null,
            )
            .scaleY(
              begin: 0.5,
              end: 1.0,
              duration: Duration(milliseconds: 300 + (index * 30)),
              curve: Curves.easeInOut,
            );
      }),
    );
  }

  Widget _buildCompactControls() {
    if (!_controller.isRecording.value && !_controller.isPaused.value) {
      // Start recording button
      return GestureDetector(
        onTap: _startCountdown,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.mic,
            size: 28,
            color: Colors.white,
          ),
        ).animate().scale(duration: 300.ms),
      );
    }

    // Recording controls
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause/Resume
        GestureDetector(
          onTap: () {
            if (_controller.isPaused.value) {
              _controller.resumeRecording();
            } else {
              _controller.pauseRecording();
            }
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _colorController.primaryColor.value.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _controller.isPaused.value ? Icons.play_arrow : Icons.pause,
              color: _colorController.primaryColor.value,
              size: 24,
            ),
          ),
        ),

        const SizedBox(width: 24),

        // Stop
        GestureDetector(
          onTap: _stopRecording,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.stop,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaveDialog(AppLocalizations l10n) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.1,
              vertical: MediaQuery.of(context).size.height * 0.1,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _colorController.primaryColor.value,
                  _colorController.primaryColor.value.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success icon
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 32,
                        color: Colors.green,
                      ),
                    )
                        .animate()
                        .scale(duration: 400.ms, curve: Curves.elasticOut),

                    const SizedBox(height: 20),

                    const Text(
                      'Recording Complete!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

// Name input
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Recording Name',
                        labelStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.white, width: 2),
                        ),
                        prefixIcon: Icon(Icons.edit,
                            color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Privacy toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          _isPublic ? 'Public Recording' : 'Private Recording',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _isPublic
                              ? 'Anyone can listen to this recording'
                              : 'Only you can listen to this recording',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        value: _isPublic,
                        onChanged: (value) {
                          setDialogState(() => _isPublic = value);
                        },
                        activeTrackColor: Colors.white,
                        inactiveThumbColor: Colors.grey.withValues(alpha: 0.5),
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Upload to Drive checkbox
                    Obx(() => Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CheckboxListTile(
                            title: const Text(
                              'Upload to Google Drive',
                              style: TextStyle(color: Colors.white),
                            ),
                            subtitle: _controller.isDriveSignedIn.value
                                ? Text(
                                    'Signed in as ${_controller.userEmail.value}',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                    ),
                                  )
                                : Text(
                                    'You will be prompted to sign in',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                            value: _uploadToDrive,
                            onChanged: (value) {
                              setDialogState(
                                  () => _uploadToDrive = value ?? false);
                            },
                            checkColor: Colors.white,
                            fillColor: WidgetStateProperty.all(
                                Colors.white.withValues(alpha: 0.2)),
                          ),
                        )),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Get.back();
                              widget.onClose();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.5)),
                            ),
                            child: Text(
                              'Discard',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveRecording,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.white,
                              foregroundColor:
                                  _colorController.primaryColor.value,
                            ),
                            child: Text(l10n.save),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUploadProgressDialog(UserRecording recording,
      {bool isPublic = false}) {
    final l10n = AppLocalizations.of(Get.context!)!;
    // Trigger upload when dialog is shown
    _controller.uploadToDrive(recording).then((_) async {
      // If marked as public, publish to Firestore after upload
      if (isPublic) {
        // Get the updated recording with Drive info
        final updatedRecording = _controller.recordings
            .firstWhereOrNull((r) => r.id == recording.id);
        if (updatedRecording != null) {
          await _controller.publishRecording(updatedRecording);
        }
      }
    });

    // Use Get.dialog instead of showDialog to avoid context issues
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(Get.context!).size.width * 0.15,
            vertical: MediaQuery.of(Get.context!).size.height * 0.2,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _colorController.primaryColor.value,
                _colorController.primaryColor.value.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(Get.context!).size.height * 0.5,
              maxWidth: MediaQuery.of(Get.context!).size.width * 0.7,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        color: Colors.white,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Uploading to Drive',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Obx(() {
                    final isUploading =
                        _controller.isUploadingRecording(recording.id);
                    final uploadError =
                        _controller.getUploadError(recording.id);

                    if (isUploading) {
                      return Column(
                        children: [
                          const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Uploading...',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      );
                    } else if (uploadError != null) {
                      return Column(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Upload Failed',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            uploadError,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _controller.retryUpload(recording);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor:
                                        _colorController.primaryColor.value,
                                  ),
                                  child: Text(l10n.retry),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    Get.back();
                                    _controller.hideOverlay();
                                    widget.onClose();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.2),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(l10n.skip),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      // Success
                      return Column(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: Colors.white, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Upload Complete!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Get.back();
                              _controller.hideOverlay();
                              widget.onClose();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor:
                                  _colorController.primaryColor.value,
                            ),
                            child: Text(l10n.done),
                          ),
                        ],
                      );
                    }
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
