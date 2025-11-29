import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/user_recording.dart';
import '../../../controller/color_controller.dart';

class RecordingTileInfo extends StatelessWidget {
  final UserRecording recording;
  final bool isPublic;
  final ColorController colorController = Get.find<ColorController>();

  RecordingTileInfo({
    super.key,
    required this.recording,
    required this.isPublic,
  });

String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds.toString().padLeft(2, '0')}s';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recording.title,
            style: TextStyle(
              color: colorController.textColor.value,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 12,
                color: colorController.textColor.value.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDuration(recording.durationSeconds),
                style: TextStyle(
                  color: colorController.textColor.value.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.calendar_today,
                size: 12,
                color: colorController.textColor.value.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Text(
                _formatDate(recording.createdAt),
                style: TextStyle(
                  color: colorController.textColor.value.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              if (isPublic && recording.userName != null) ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.person_outline,
                  size: 12,
                  color: colorController.textColor.value.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    recording.userName!,
                    style: TextStyle(
                      color: colorController.textColor.value
                          .withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
