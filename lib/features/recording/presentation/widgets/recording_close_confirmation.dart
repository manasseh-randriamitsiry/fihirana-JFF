import 'package:flutter/material.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class RecordingCloseConfirmation extends StatelessWidget {
  final RecordingController controller;
  final ColorController colorController;
  final AppLocalizations l10n;
  final VoidCallback onDiscard;
  final VoidCallback onSave;

  const RecordingCloseConfirmation({
    super.key,
    required this.controller,
    required this.colorController,
    required this.l10n,
    required this.onDiscard,
    required this.onSave,
  });

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colorController.backgroundColor.value,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.stop_circle, color: Colors.red, size: 24),
          const SizedBox(width: 12),
          Text(
            'Stop Recording?',
            style: TextStyle(
              color: colorController.textColor.value,
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
            'What would you like to do with this recording?',
            style: TextStyle(
              color: colorController.textColor.value,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  colorController.primaryColor.value.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorController.primaryColor.value
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  color: colorController.primaryColor.value,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(controller.recordDuration.value),
                  style: TextStyle(
                    color: colorController.textColor.value,
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
            'Cancel',
            style: TextStyle(color: colorController.textColor.value),
          ),
        ),
        TextButton(
          onPressed: onDiscard,
          style: TextButton.styleFrom(foregroundColor: Colors.orange),
          child: Text(l10n.discard),
        ),
        ElevatedButton(
          onPressed: onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorController.primaryColor.value,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.saveRecording),
        ),
      ],
    );
  }
}