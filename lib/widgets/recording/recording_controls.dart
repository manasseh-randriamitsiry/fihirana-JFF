import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controller/recording_controller.dart';
import '../../controller/color_controller.dart';

class RecordingControls extends StatelessWidget {
  final RecordingController controller;
  final ColorController colorController;
  final AnimationController pulseController;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const RecordingControls({
    super.key,
    required this.controller,
    required this.colorController,
    required this.pulseController,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.isRecording.value && !controller.isPaused.value) {
      // Start recording button
      return GestureDetector(
        onTap: onStartRecording,
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
            if (controller.isPaused.value) {
              controller.resumeRecording();
            } else {
              controller.pauseRecording();
            }
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorController.primaryColor.value.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              controller.isPaused.value ? Icons.play_arrow : Icons.pause,
              color: colorController.primaryColor.value,
              size: 24,
            ),
          ),
        ),

        const SizedBox(width: 24),

        // Stop
        GestureDetector(
          onTap: onStopRecording,
          child: AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (pulseController.value * 0.1),
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
}