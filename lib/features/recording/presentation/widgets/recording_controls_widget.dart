import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';

class RecordingControlsWidget extends StatefulWidget {
  final bool isRecording;
  final bool isPaused;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const RecordingControlsWidget({
    super.key,
    required this.isRecording,
    required this.isPaused,
    required this.onStart,
    required this.onStop,
    required this.onPause,
    required this.onResume,
  });

  @override
  State<RecordingControlsWidget> createState() =>
      _RecordingControlsWidgetState();
}

class _RecordingControlsWidgetState extends State<RecordingControlsWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    if (!widget.isRecording && !widget.isPaused) {
      // Start recording button
      return GestureDetector(
        onTap: widget.onStart,
        child: Container(
          width: 80,
          height: 80,
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
            Icons.mic,
            size: 40,
            color: Colors.white,
          ),
        ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
      );
    }

    // Recording controls
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause/Resume button
        GestureDetector(
          onTap: widget.isPaused ? widget.onResume : widget.onPause,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: widget.isPaused
                  ? colorController.primaryColor.value
                  : colorController.primaryColor.value.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              boxShadow: widget.isPaused
                  ? [
                      BoxShadow(
                        color: colorController.primaryColor.value
                            .withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              widget.isPaused ? Icons.play_arrow : Icons.pause,
              color: widget.isPaused
                  ? Colors.white
                  : colorController.primaryColor.value,
              size: 32,
            ),
          ),
        ),

        const SizedBox(width: 32),

        // Stop button with enhanced visual feedback
        GestureDetector(
          onTap: widget.onStop,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer ring effect
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                      ),
                      // Stop icon
                      const Icon(
                        Icons.stop,
                        size: 36,
                        color: Colors.white,
                      ),
                    ],
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
