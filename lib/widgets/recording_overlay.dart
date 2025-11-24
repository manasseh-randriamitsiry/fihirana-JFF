import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controller/recording_controller.dart';
import '../controller/color_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/user_recording.dart';

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
  final RecordingController _controller =
      Get.put(RecordingController(), permanent: true);
  final ColorController _colorController = Get.find<ColorController>();

  late AnimationController _countdownController;
  late AnimationController _pulseController;
  int _countdown = 3;
  bool _isCountingDown = false;
  bool _showSaveDialog = false;
  bool _isExpanded = false; // Default to collapsed (FAB)

  final TextEditingController _nameController = TextEditingController();
  bool _uploadToDrive = false;
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();

    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Auto-generate recording name
    _nameController.text =
        '${widget.hymnTitle} - ${DateTime.now().toString().substring(0, 16)}';

    // Update controller state
    _controller.showOverlay(widget.hymnId, widget.hymnTitle);
  }

  @override
  void dispose() {
    _countdownController.dispose();
    _pulseController.dispose();
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
    final recording =
        await _controller.stopRecording(widget.hymnId, widget.hymnTitle);
    if (recording != null) {
      setState(() => _showSaveDialog = true);
    }
  }

  void _saveRecording() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Error', 'Please enter a name for the recording');
      return;
    }

    // Update recording name
    if (_controller.recordings.isNotEmpty) {
      final recording = _controller.recordings.last;
      // In a real app, you'd update the recording name in the DB/File here
      // For now we just proceed

      if (_uploadToDrive) {
        // Show upload progress in dialog
        setState(() => _showSaveDialog = false);
        _showUploadProgressDialog(recording);
      } else {
        _controller.hideOverlay();
        widget.onClose();
      }
    } else {
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Recording?'),
        content: const Text('Are you sure you want to stop recording?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _stopRecording();
            },
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // If showing save dialog, take up full screen
    if (_showSaveDialog) {
      return Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: _buildSaveDialog(l10n),
      );
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
                      'Hymn ${widget.hymnId}',
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
      child: Container(
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
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

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
                    labelStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.8)),
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
                      setState(() => _isPublic = value);
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
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              )
                            : Text(
                                'You will be prompted to sign in',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                        value: _uploadToDrive,
                        onChanged: (value) {
                          setState(() => _uploadToDrive = value ?? false);
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
                        onPressed: widget.onClose,
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
                          foregroundColor: _colorController.primaryColor.value,
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUploadProgressDialog(UserRecording recording) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.15,
            vertical: MediaQuery.of(context).size.height * 0.2,
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
              maxHeight: MediaQuery.of(context).size.height * 0.5,
              maxWidth: MediaQuery.of(context).size.width * 0.7,
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
                          Text(
                            'Upload Failed',
                            style: const TextStyle(
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
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _controller.hideOverlay();
                              widget.onClose();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Close'),
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
                              Navigator.pop(context);
                              _controller.hideOverlay();
                              widget.onClose();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor:
                                  _colorController.primaryColor.value,
                            ),
                            child: const Text('Done'),
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
