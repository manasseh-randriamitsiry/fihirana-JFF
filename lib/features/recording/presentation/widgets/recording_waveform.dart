import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';

class RecordingWaveform extends StatelessWidget {
  final RecordingController controller;
  final ColorController colorController;

  const RecordingWaveform({
    super.key,
    required this.controller,
    required this.colorController,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(15, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 30)),
          width: 4,
          height: controller.isRecording.value ? 10 + (index % 4) * 8.0 : 10,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: controller.isRecording.value
                ? colorController.primaryColor.value
                : colorController.primaryColor.value.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        )
            .animate(
              onPlay: (controller) => this.controller.isRecording.value
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
}
