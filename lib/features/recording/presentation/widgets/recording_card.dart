import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'recording_countdown.dart';
import 'recording_waveform.dart';
import 'recording_controls.dart';

class RecordingCard extends StatelessWidget {
  final RecordingController controller;
  final ColorController colorController;
  final AppLocalizations l10n;
  final String hymnTitle;
  final String hymnId;
  final bool isCountingDown;
  final int countdown;
  final AnimationController countdownController;
  final AnimationController pulseController;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onClose;
  final VoidCallback onMinimize;

  const RecordingCard({
    super.key,
    required this.controller,
    required this.colorController,
    required this.l10n,
    required this.hymnTitle,
    required this.hymnId,
    required this.isCountingDown,
    required this.countdown,
    required this.countdownController,
    required this.pulseController,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onClose,
    required this.onMinimize,
  });

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorController.backgroundColor.value,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: colorController.primaryColor.value.withValues(alpha: 0.2),
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
                      hymnTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorController.textColor.value,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Hira $hymnId',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorController.textColor.value
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (controller.isRecording.value)
                IconButton(
                  icon:
                      Icon(Icons.close, color: colorController.textColor.value),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.keyboard_arrow_down,
                    color: colorController.textColor.value),
                onPressed: onMinimize,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Content
          if (isCountingDown)
            SizedBox(
              height: 100,
              child: RecordingCountdown(
                colorController: colorController,
                countdownController: countdownController,
                countdown: countdown,
              ),
            )
          else
            Column(
              children: [
                // Waveform placeholder or visualizer
                SizedBox(
                  height: 40,
                  child: RecordingWaveform(
                    controller: controller,
                    colorController: colorController,
                  ),
                ),

                const SizedBox(height: 12),

                // Timer
                Obx(() => Text(
                      _formatDuration(controller.recordDuration.value),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: colorController.primaryColor.value,
                      ),
                    )),

                const SizedBox(height: 16),

                // Controls
                RecordingControls(
                  controller: controller,
                  colorController: colorController,
                  pulseController: pulseController,
                  onStartRecording: onStartRecording,
                  onStopRecording: onStopRecording,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
