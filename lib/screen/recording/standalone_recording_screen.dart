import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/recording_controller.dart';
import '../../controller/color_controller.dart';
import '../../widgets/recording/recording_controls_widget.dart';
import '../../widgets/recording/recording_save_dialog_widget.dart';

class StandaloneRecordingScreen extends StatefulWidget {
  const StandaloneRecordingScreen({super.key});

  @override
  State<StandaloneRecordingScreen> createState() => _StandaloneRecordingScreenState();
}

class _StandaloneRecordingScreenState extends State<StandaloneRecordingScreen> {
  final RecordingController _controller = Get.find<RecordingController>();
  final ColorController _colorController = Get.find<ColorController>();
  final TextEditingController _nameController = TextEditingController();
  
  bool _showSaveDialog = false;
  String _recordingTitle = '';

  @override
  void initState() {
    super.initState();
    _initializeRecordingName();
    // Ensure overlay is hidden when entering standalone recording
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.hideOverlay();
    });
  }

  void _initializeRecordingName() {
    final now = DateTime.now();
    final timestamp = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _recordingTitle = 'Unknown Recording - $timestamp';
    _nameController.text = _recordingTitle;
  }

  @override
  void dispose() {
    _nameController.dispose();
    // Ensure overlay is hidden when leaving standalone recording
    _controller.hideOverlay();
    super.dispose();
  }

  void _startRecording() async {
    // Ensure we're not already recording and overlay is hidden
    if (_controller.isRecording.value) {
      Get.snackbar('Info', 'Recording already in progress');
      return;
    }
    
    // Hide any existing overlay and reset overlay state
    _controller.hideOverlay();
    
    // Use a slight delay to ensure overlay is fully hidden
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Start recording
    await _controller.startRecording('unknown');
  }

  void _stopRecording() async {
    // Ensure overlay doesn't interfere
    _controller.hideOverlay();
    
    // Stop recording immediately and show save dialog
    final recording = await _controller.stopRecording('unknown', _recordingTitle);
    if (recording != null) {
      setState(() => _showSaveDialog = true);
    }
  }

  void _saveRecording({bool closeAfterSave = true}) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Error', 'Please enter a name for the recording');
      return;
    }

    // Update recording name if different
    if (name != _recordingTitle) {
      final lastRecording = _controller.recordings.last;
      await _controller.renameRecording(lastRecording, name);
    }

    setState(() => _showSaveDialog = false);
    
    if (closeAfterSave) {
      Get.back(); // Go back to recording list
      Get.snackbar('Success', 'Recording saved successfully');
    } else {
      Get.snackbar('Success', 'Recording saved. You can start a new recording.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSaveDialog) {
      return RecordingSaveDialogWidget(
        nameController: _nameController,
        onSave: _saveRecording,
        onDiscard: () {
          setState(() => _showSaveDialog = false);
          Get.back();
        },
      );
    }

    return Scaffold(
      backgroundColor: _colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: _colorController.backgroundColor.value,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: _colorController.textColor.value),
          onPressed: () {
            if (_controller.isRecording.value) {
              _showCloseConfirmation();
            } else {
              Get.back();
            }
          },
        ),
        title: Text(
          'New Recording',
          style: TextStyle(
            color: _colorController.textColor.value,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Recording name input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _colorController.backgroundColor.value,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _colorController.primaryColor.value.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recording Name',
                      style: TextStyle(
                        color: _colorController.textColor.value,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(
                        color: _colorController.textColor.value,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter recording name...',
                        hintStyle: TextStyle(
                          color: _colorController.textColor.value.withValues(alpha: 0.5),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _colorController.primaryColor.value.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _colorController.primaryColor.value.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _colorController.primaryColor.value,
                            width: 2,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.edit,
                          color: _colorController.primaryColor.value,
                        ),
                      ),
                      onChanged: (value) {
                        _recordingTitle = value.trim();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Recording visualizer and controls
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Recording status
                    Obx(() => Text(
                      _controller.isRecording.value ? 'Recording...' : 'Ready to Record',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _controller.isRecording.value 
                            ? Colors.red 
                            : _colorController.textColor.value,
                      ),
                    )),

                    const SizedBox(height: 16),

                    // Timer
                    Obx(() => Text(
                      _formatDuration(_controller.recordDuration.value),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: _colorController.primaryColor.value,
                      ),
                    )),

                    const SizedBox(height: 40),

                    // Recording controls
                    RecordingControlsWidget(
                      isRecording: _controller.isRecording.value,
                      isPaused: _controller.isPaused.value,
                      onStart: _startRecording,
                      onStop: _stopRecording,
                      onPause: _controller.pauseRecording,
                      onResume: _controller.resumeRecording,
                    ),

                    // Dedicated stop button - always visible when recording
                    Obx(() => _controller.isRecording.value
                        ? Container(
                            margin: const EdgeInsets.only(top: 32),
                            child: ElevatedButton.icon(
                              onPressed: _stopRecording,
                              icon: const Icon(Icons.stop, size: 20),
                              label: const Text('Stop Recording'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 4,
                              ),
                            ),
                          )
                        : const SizedBox.shrink()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        backgroundColor: _colorController.backgroundColor.value,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Text(
              'Recording in Progress',
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
              'You have a recording in progress. What would you like to do?',
              style: TextStyle(
                color: _colorController.textColor.value,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _colorController.primaryColor.value.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
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
              'Continue Recording',
              style: TextStyle(color: _colorController.primaryColor.value),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _controller.stopRecording('unknown', _recordingTitle);
              Get.back();
              Get.snackbar('Discarded', 'Recording was not saved');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Discard & Exit'),
          ),
        ],
      ),
    );
  }
}