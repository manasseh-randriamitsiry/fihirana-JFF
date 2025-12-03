import 'package:flutter/material.dart';
import '../../controller/color_controller.dart';

class RecordingCountdown extends StatelessWidget {
  final ColorController colorController;
  final AnimationController countdownController;
  final int countdown;

  const RecordingCountdown({
    super.key,
    required this.colorController,
    required this.countdownController,
    required this.countdown,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: countdownController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (countdownController.value * 0.3),
            child: Opacity(
              opacity: 1.0 - countdownController.value,
              child: Text(
                countdown.toString(),
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: colorController.primaryColor.value,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}