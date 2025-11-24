import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../controller/recording_controller.dart';
import '../controller/color_controller.dart';
import '../l10n/app_localizations.dart';

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

  final TextEditingController _nameController = TextEditingController();
  bool _uploadToDrive = false;
  bool _isPublic = false; // Privacy setting: false = private, true = public

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
  }

  @override
  void dispose() {
    _countdownController.dispose();
    _pulseController.dispose();
    _nameController.dispose();
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
      // TODO: Implement rename functionality

      if (_uploadToDrive && _controller.isDriveSignedIn.value) {
        await _controller.uploadToDrive(recording);
      }
    }

    widget.onClose();
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

    return Container(
      color: _colorController.backgroundColor.value.withValues(alpha: 0.95),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(l10n),

            const SizedBox(height: 40),

            // Main content
            Expanded(
              child: _isCountingDown
                  ? _buildCountdown()
                  : _buildRecordingView(l10n),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close, color: _colorController.iconColor.value),
            onPressed: () {
              if (_controller.isRecording.value) {
                _showCloseConfirmation();
              } else {
                widget.onClose();
              }
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  widget.hymnTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _colorController.textColor.value,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Hymn ${widget.hymnId}',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        _colorController.textColor.value.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          if (widget.onMinimize != null && _controller.isRecording.value)
            IconButton(
              icon:
                  Icon(Icons.minimize, color: _colorController.iconColor.value),
              onPressed: widget.onMinimize,
            )
          else
            const SizedBox(width: 48),
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
                  fontSize: 120,
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

  Widget _buildRecordingView(AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Waveform / Level Indicator
        Obx(() => _buildWaveform()),

        const SizedBox(height: 40),

        // Timer
        Obx(() => Text(
              _formatDuration(_controller.recordDuration.value),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: _colorController.textColor.value,
              ),
            )),

        const SizedBox(height: 60),

        // Controls
        Obx(() => _buildControls(l10n)),
      ],
    );
  }

  Widget _buildWaveform() {
    // Simple animated bars as waveform visualization
    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(20, (index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 50)),
            width: 8,
            height:
                _controller.isRecording.value ? 20 + (index % 5) * 15.0 : 20,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _controller.isRecording.value
                  ? _colorController.primaryColor.value
                  : _colorController.iconColor.value.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
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
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeInOut,
              );
        }),
      ),
    );
  }

  Widget _buildControls(AppLocalizations l10n) {
    if (!_controller.isRecording.value && !_controller.isPaused.value) {
      // Start recording button
      return FloatingActionButton.large(
        onPressed: _startCountdown,
        backgroundColor: Colors.red,
        child: const Icon(Icons.mic, size: 40, color: Colors.white),
      ).animate().scale(duration: 300.ms);
    }

    // Recording controls
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause/Resume
        FloatingActionButton(
          onPressed: () {
            if (_controller.isPaused.value) {
              _controller.resumeRecording();
            } else {
              _controller.pauseRecording();
            }
          },
          backgroundColor: _colorController.primaryColor.value,
          child: Icon(
            _controller.isPaused.value ? Icons.play_arrow : Icons.pause,
            color: Colors.white,
          ),
        ),

        const SizedBox(width: 40),

        // Stop
        FloatingActionButton.large(
          onPressed: _stopRecording,
          backgroundColor: Colors.red,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: const Icon(Icons.stop, size: 40, color: Colors.white),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaveDialog(AppLocalizations l10n) {
    return Container(
      color: _colorController.backgroundColor.value,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

          const SizedBox(height: 24),

          Text(
            'Recording Complete!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _colorController.textColor.value,
            ),
          ),

          const SizedBox(height: 40),

          // Name input
          TextField(
            controller: _nameController,
            style: TextStyle(color: _colorController.textColor.value),
            decoration: InputDecoration(
              labelText: 'Recording Name',
              labelStyle: TextStyle(color: _colorController.textColor.value),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon:
                  Icon(Icons.edit, color: _colorController.iconColor.value),
            ),
          ),

          const SizedBox(height: 24),

          // Privacy toggle
          Card(
            color: _colorController.primaryColor.value.withValues(alpha: 0.1),
            child: SwitchListTile(
              title: Text(
                _isPublic ? 'Public Recording' : 'Private Recording',
                style: TextStyle(
                  color: _colorController.textColor.value,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                _isPublic
                    ? 'Anyone can listen to this recording'
                    : 'Only you can listen to this recording',
                style: TextStyle(
                  color:
                      _colorController.textColor.value.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              value: _isPublic,
              onChanged: (value) {
                setState(() => _isPublic = value);
              },

              secondary: Icon(
                _isPublic ? Icons.public : Icons.lock,
                color: _colorController.iconColor.value,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Upload to Drive checkbox
          Obx(() => CheckboxListTile(
                title: Text(
                  'Upload to Google Drive',
                  style: TextStyle(color: _colorController.textColor.value),
                ),
                subtitle: _controller.isDriveSignedIn.value
                    ? Text(
                        'Signed in as ${_controller.userEmail.value}',
                        style: TextStyle(
                          color: _colorController.textColor.value
                              .withValues(alpha: 0.7),
                        ),
                      )
                    : Text(
                        'You will be prompted to sign in',
                        style: TextStyle(
                          color: _colorController.textColor.value
                              .withValues(alpha: 0.7),
                        ),
                      ),
                value: _uploadToDrive,
                onChanged: (value) {
                  setState(() => _uploadToDrive = value ?? false);
                },
              )),

          const SizedBox(height: 40),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClose,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side:
                        BorderSide(color: _colorController.primaryColor.value),
                  ),
                  child: Text(
                    'Discard',
                    style:
                        TextStyle(color: _colorController.primaryColor.value),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveRecording,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _colorController.primaryColor.value,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCloseConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Recording?'),
        content: const Text('Your recording will be lost if you close now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Recording'),
          ),
          TextButton(
            onPressed: () async {
              await _controller.stopRecording(widget.hymnId, widget.hymnTitle);
              if (mounted) {
                Navigator.pop(context);
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
