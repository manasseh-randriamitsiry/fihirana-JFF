import 'package:flutter/material.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';

class RecordingTileInfo extends StatelessWidget {
  final UserRecording recording;
  final bool isPublic;

  const RecordingTileInfo({
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

  String _getDisplayTitle() {
    if (recording.title.isNotEmpty) {
      return recording.title;
    }

    // Fallback for recordings without titles
    if (recording.hymnId != 'standalone' && recording.hymnId.isNotEmpty) {
      return 'Hymn ${recording.hymnId}';
    }

    // For standalone recordings or unknown hymns
    final date = recording.createdAt;
    final timeString =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return 'Recording ${date.day}/${date.month}/${date.year} $timeString';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getDisplayTitle(),
          style: TextStyle(
            color: colors.onSurface,
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
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDuration(recording.durationSeconds),
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.calendar_today,
              size: 12,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDate(recording.createdAt),
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            if (isPublic && recording.userName != null) ...[
              const SizedBox(width: 12),
              Icon(
                Icons.person_outline,
                size: 12,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  recording.userName!,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
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
    );
  }
}
