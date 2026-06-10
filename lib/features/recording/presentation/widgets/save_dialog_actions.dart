import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';

class SaveDialogActions extends StatefulWidget {
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final bool uploadToDrive;
  final bool isPublic;

  const SaveDialogActions({
    super.key,
    required this.onSave,
    required this.onDiscard,
    required this.uploadToDrive,
    required this.isPublic,
  });

  @override
  State<SaveDialogActions> createState() => _SaveDialogActionsState();
}

class _SaveDialogActionsState extends State<SaveDialogActions> {
  final RecordingController recordingController =
      Get.find<RecordingController>();
  final ColorController colorController = Get.find<ColorController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary save button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              // Save recording first
              widget.onSave();

              // Handle upload and public sharing if needed
              if (widget.uploadToDrive || widget.isPublic) {
                final lastRecording = recordingController.recordings.last;
                if (widget.uploadToDrive) {
                  await recordingController.uploadToDrive(lastRecording);
                }
                if (widget.isPublic) {
                  await recordingController.publishRecording(lastRecording);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.white,
              foregroundColor: colorController.primaryColor.value,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save, size: 20),
                SizedBox(width: 8),
                Text('Save & Close',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Secondary options
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onDiscard,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Discard',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  // Save but don't close - allow new recording
                  widget.onSave();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add,
                        size: 16, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 4),
                    Text(
                      'Save & New',
                      style:
                          TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
