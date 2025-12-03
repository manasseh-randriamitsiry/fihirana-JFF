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
    // Check if we have a valid photo URL
    final hasPhotoUrl =
        recording.userPhotoUrl != null && recording.userPhotoUrl!.isNotEmpty;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: hasPhotoUrl
            ? Colors.transparent
            : (isPublic
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(12),
        gradient: hasPhotoUrl
            ? null
            : LinearGradient(
                colors: isPublic
                    ? [
                        Colors.blue.withValues(alpha: 0.1),
                        Colors.purple.withValues(alpha: 0.1)
                      ]
                    : [
                        Colors.orange.withValues(alpha: 0.1),
                        Colors.deepOrange.withValues(alpha: 0.1)
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
                    color: Colors.grey[200],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.person,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
              )
            : Icon(
                isPublic ? Icons.person : Icons.music_note_rounded,
                color: isPublic ? Colors.blue : Colors.orange,
                size: 24,
              ),
      ),
    );
  }
}
