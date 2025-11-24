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
  late AnimationController _slideController;
  int _countdown = 3;
  bool _isCountingDown = false;
  bool _showSaveDialog = false;
  bool _isCollapsed = false;

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

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

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
    _slideController.dispose();
    _nameController.dispose();
    // Only hide overlay if not minimized (recording continues in background)
    if (!_controller.isOverlayMinimized.value) {
      _controller.hideOverlay();
    }
    super.dispose();
  }

  void _startCountdown() async {
    setState(() {
      _isCountingDown = true;
      _countdown = 3;
    });

    for (int i = 3; i > 0; i--) {
      setState(() => _countdown = i);
      _countdownController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 1000));
    }

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

  void _toggleCollapse() {
    if (_isCollapsed) {
      _expandOverlay();
    } else {
      _collapseOverlay();
    }
  }

  void _collapseOverlay() {
    _slideController.reverse();
    setState(() => _isCollapsed = true);
  }

  void _expandOverlay() {
    _slideController.forward();
    setState(() => _isCollapsed = false);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_showSaveDialog) {
      return _buildSaveDialog(l10n);
    }

    return GestureDetector(
      onTap: _toggleCollapse,
      behavior: HitTestBehavior.translucent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Stack(
          children: [
            // Tap-outside-to-collapse area
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleCollapse,
                behavior: HitTestBehavior.translucent,
              ),
            ),
            // Main overlay content
            AnimatedBuilder(
              animation: _slideController,
              builder: (context, child) {
                final slideOffset = _isCollapsed 
                    ? MediaQuery.of(context).size.height * 0.7 
                    : 0.0;
                
                return Transform.translate(
                  offset: Offset(0, slideOffset),
                  child: child!,
                );
              },
              child: _buildOverlayContent(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayContent(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _colorController.primaryColor.value.withValues(alpha: 0.95),
            _colorController.primaryColor.value.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(0),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            child: Container(
              color: _colorController.backgroundColor.value.withValues(alpha: 0.9),
              child: Column(
                children: [
                  // Compact header
                  _buildCompactHeader(l10n),
                  
                  const SizedBox(height: 16),
                  
                  // Main content
                  Expanded(
                    child: _isCountingDown
                        ? _buildCountdown()
                        : _buildRecordingView(l10n),
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: () {
              if (_controller.isRecording.value) {
                _showCloseConfirmation();
              } else {
                _controller.hideOverlay();
                widget.onClose();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.close,
                color: _colorController.textColor.value,
                size: 20,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Title
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.hymnTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Hymn ${widget.hymnId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Minimize button
          if (widget.onMinimize != null && _controller.isRecording.value)
            GestureDetector(
              onTap: () {
                _controller.minimizeOverlay();
                widget.onMinimize?.call();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            )
          else
            const SizedBox(width: 36),
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
                style: const TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordingView(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Compact waveform
        SizedBox(
          height: 60,
          child: Obx(() => _buildCompactWaveform()),
        ),

        const SizedBox(height: 24),

        // Timer
        Obx(() => Text(
              _formatDuration(_controller.recordDuration.value),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: Colors.white,
              ),
            )),

        const SizedBox(height: 32),

        // Compact controls
        Obx(() => _buildCompactControls()),
      ],
    );
  }

  Widget _buildCompactWaveform() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(15, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 30)),
          width: 6,
          height:
              _controller.isRecording.value ? 15 + (index % 4) * 10.0 : 15,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: _controller.isRecording.value
                ? Colors.white
                : Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
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
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.4),
                blurRadius: 12,
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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _controller.isPaused.value ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
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
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 16,
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
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white, width: 2),
                    ),
                    prefixIcon: Icon(Icons.edit, color: Colors.white.withValues(alpha: 0.8)),
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
                    fillColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.2)),
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
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          'Discard',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
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
                    final isUploading = _controller.isUploadingRecording(recording.id);
                    final uploadError = _controller.getUploadError(recording.id);
                    
                    if (isUploading) {
                      return Column(
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Uploading "${recording.title}"...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    } else if (uploadError != null) {
                      return Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 40,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Upload Failed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            uploadError,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    } else {
                      return const Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 40,
                            color: Colors.green,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Upload Complete!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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

  void _showCloseConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _colorController.backgroundColor.value,
        title: const Text('Stop Recording?'),
        content: const Text('Your recording will be lost if you close now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Recording'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _controller.stopRecording(widget.hymnId, widget.hymnTitle);
              if (mounted) {
                navigator.pop();
                _controller.hideOverlay();
                widget.onClose();
              }
            },
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}