import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../controller/recording_controller.dart';
import '../../controller/color_controller.dart';
import '../../widgets/recording/recording_controls_widget.dart';
import '../../l10n/app_localizations.dart';

class StandaloneRecordingScreen extends StatefulWidget {
  const StandaloneRecordingScreen({super.key});

  @override
  State<StandaloneRecordingScreen> createState() => _StandaloneRecordingScreenState();
}

class _StandaloneRecordingScreenState extends State<StandaloneRecordingScreen> {
  final RecordingController _controller = Get.find<RecordingController>();
  final ColorController _colorController = Get.find<ColorController>();
  final TextEditingController _nameController = TextEditingController();
  
  String _recordingTitle = '';

  @override
  void initState() {
    super.initState();
    _initializeRecordingName();
    // Ensure overlay is hidden when entering standalone recording
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.hideOverlay();
      // Initialize recording service
      _controller.onPageVisible();
      // Multiple checks to ensure overlay is hidden
      for (int i = 0; i < 3; i++) {
        Future.delayed(Duration(milliseconds: 100 * (i + 1)), () {
          if (mounted) {
            _controller.hideOverlay();
          }
        });
      }
    });
  }

  void _initializeRecordingName() {
    final now = DateTime.now();
    final timestamp = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _recordingTitle = 'Recording - $timestamp';
    _nameController.text = _recordingTitle;
  }

  @override
  void dispose() {
    _nameController.dispose();
    // Don't call controller methods during dispose as they may trigger Obx updates
    // _controller.hideOverlay(); // Remove this to prevent Obx updates during disposal
    super.dispose();
  }

  void _startRecording() async {
    // Ensure we're not already recording and overlay is hidden
    if (_controller.isRecording.value) {
      Get.snackbar('Info', 'Recording already in progress');
      return;
    }
    
    _controller.hideOverlay();
    
    // Start recording without hymn context
    try {
      await _controller.startRecording('standalone');
    } catch (e) {
      if (mounted) {
        Get.snackbar('Error', 'Failed to start recording: $e');
      }
    }
  }

  void _stopRecording() async {
    try {
      if (kDebugMode) {
        print('StandaloneRecording: Stopping recording...');
      }
      // Use current text from name controller instead of _recordingTitle
      final currentTitle = _nameController.text.trim().isNotEmpty 
          ? _nameController.text.trim() 
          : _recordingTitle;
      if (kDebugMode) {
        print('StandaloneRecording: Using title: "$currentTitle"');
        print('StandaloneRecording: Name controller text: "${_nameController.text}"');
      }
      
      final recording = await _controller.stopRecording('standalone', currentTitle);
      if (kDebugMode) {
        print('StandaloneRecording: Recording result title: ${recording?.title}');
        print('StandaloneRecording: Recording result: $recording');
      }
      if (recording != null && mounted) {
        _showSaveDialog();
      } else if (mounted && recording == null) {
        Get.snackbar('Error', 'Failed to save recording - no recording returned');
      }
    } catch (e) {
      if (kDebugMode) {
        print('StandaloneRecording: Error stopping recording: $e');
      }
      if (mounted) {
        Get.snackbar('Error', 'Failed to stop recording: $e');
      }
    }
  }

  void _saveRecording() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Error', 'Please enter a name for the recording');
      return;
    }

    // Close dialog first to prevent widget tree conflicts
    if (mounted) {
      Navigator.pop(context);
    }

    // Update recording name if user changed it after stopping recording
    try {
      final recordings = _controller.recordings;
      if (recordings.isNotEmpty) {
        final lastRecording = recordings.last;
        // Only rename if the name is different from current recording title
        if (lastRecording.title != name) {
          if (kDebugMode) {
            print('StandaloneRecording: Renaming from "${lastRecording.title}" to "$name"');
          }
          await _controller.renameRecording(lastRecording, name);
        }
      }
    } catch (e) {
      debugPrint('Error renaming recording: $e');
    }

    // Navigate back after all operations are complete
    if (mounted) {
      // Add small delay to ensure widget tree is stable
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Get.back(); // Go back to previous screen
        }
      });
    }
  }

  void _discardRecording() {
    if (mounted) {
      Navigator.pop(context);
      Get.back(); // Go back to previous screen
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
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
                  ),
                  
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
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _discardRecording,
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
                          child: Text(AppLocalizations.of(context)!.save),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: _colorController.backgroundColor.value,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: _colorController.textColor.value),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Recording',
          style: TextStyle(
            color: _colorController.textColor.value,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Recording title input
              TextField(
                controller: _nameController,
                style: TextStyle(
                  color: _colorController.textColor.value,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: 'Recording Name',
                  labelStyle: TextStyle(
                    color: _colorController.textColor.value.withValues(alpha: 0.7),
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
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Recording controls
              Expanded(
                child: Center(
                  child: Obx(() {
                    // Don't update if widget is not mounted
                    if (!mounted) return const SizedBox.shrink();
                    return RecordingControlsWidget(
                      isRecording: _controller.isRecording.value,
                      isPaused: _controller.isPaused.value,
                      onStart: _startRecording,
                      onStop: _stopRecording,
                      onPause: () => _controller.pauseRecording(),
                      onResume: () => _controller.resumeRecording(),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}