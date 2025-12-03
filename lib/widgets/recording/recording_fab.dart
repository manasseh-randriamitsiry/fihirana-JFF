import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controller/recording_controller.dart';
import '../../controller/color_controller.dart';

class RecordingFab extends StatelessWidget {
  final RecordingController controller;
  final ColorController colorController;
  final AnimationController pulseController;
  final VoidCallback onTap;

  const RecordingFab({
    super.key,
    required this.controller,
    required this.colorController,
    required this.pulseController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colorController.primaryColor.value,
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
            if (controller.isRecording.value)
              AnimatedBuilder(
                animation: pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (pulseController.value * 0.3),
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
              controller.isRecording.value ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 28,
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
  }
}