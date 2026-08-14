import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';

class RecordingTileIcon extends StatelessWidget {
  final UserRecording recording;
  final bool isPublic;

  const RecordingTileIcon({
    super.key,
    required this.recording,
    required this.isPublic,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Check if we have a valid photo URL
    final hasPhotoUrl =
        recording.userPhotoUrl != null && recording.userPhotoUrl!.isNotEmpty;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: hasPhotoUrl
            ? null
            : (isPublic ? colors.secondaryContainer : colors.primaryContainer),
        borderRadius: BorderRadius.circular(12),
        gradient: hasPhotoUrl ? null : null,
      ),
      child: Center(
        child: hasPhotoUrl
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: recording.userPhotoUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: colors.surfaceContainerHighest,
                    child: Icon(Icons.person, color: colors.onSurfaceVariant),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.person,
                    color: colors.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              )
            : Icon(
                isPublic ? Icons.person : Icons.music_note_rounded,
                color: isPublic
                    ? colors.onSecondaryContainer
                    : colors.onPrimaryContainer,
                size: 24,
              ),
      ),
    );
  }
}
