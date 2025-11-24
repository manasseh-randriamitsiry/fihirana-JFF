import 'package:fihirana/controller/recording_controller.dart';
import 'package:fihirana/models/user_recording.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class RecordingManagerScreen extends StatelessWidget {
  const RecordingManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.put to ensure the controller is initialized
    final RecordingController controller =
        Get.put(RecordingController(), permanent: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recordings'),
        actions: [
          Obx(() {
            if (controller.isDriveSignedIn.value) {
              return IconButton(
                icon: const Icon(Icons.cloud_done),
                tooltip: 'Signed in as ${controller.userEmail.value}',
                onPressed: () {
                  _showDriveDialog(context, controller);
                },
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.cloud_off),
                tooltip: 'Sign in to Google Drive',
                onPressed: () => controller.signInToDrive(),
              );
            }
          }),
        ],
      ),
      body: Obx(() {
        if (controller.recordings.isEmpty) {
          return const Center(
            child: Text('No recordings yet'),
          );
        }

        return ListView.builder(
          itemCount: controller.recordings.length,
          itemBuilder: (context, index) {
            final recording = controller.recordings[index];
            return _RecordingTile(recording: recording, controller: controller);
          },
        );
      }),
    );
  }

  void _showDriveDialog(BuildContext context, RecordingController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Google Drive'),
        content: Text('Signed in as ${controller.userEmail.value}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              controller.signOutFromDrive();
              Navigator.pop(context);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _RecordingTile extends StatelessWidget {
  final UserRecording recording;
  final RecordingController controller;

  const _RecordingTile({
    required this.recording,
    required this.controller,
  });

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.music_note),
        ),
        title: Text(recording.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Hymn ${recording.hymnId} • ${_formatDuration(recording.durationSeconds)}'),
            Text(
              DateFormat.yMMMd().add_jm().format(recording.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (recording.driveFileId != null)
              const Icon(Icons.cloud_done, size: 16, color: Colors.green)
            else
              IconButton(
                icon: const Icon(Icons.cloud_upload_outlined),
                onPressed: () => controller.uploadToDrive(recording),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'share':
                    if (recording.driveWebLink != null) {
                      Share.share(
                          'Check out my recording: ${recording.driveWebLink}');
                    } else {
                      Share.shareXFiles([XFile(recording.filePath)],
                          text: recording.title);
                    }
                    break;
                  case 'delete':
                    controller.deleteRecording(recording);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Share')
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete),
                      SizedBox(width: 8),
                      Text('Delete')
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          // Play recording
          controller.playRecording(recording);
          _showPlayerSheet(context);
        },
      ),
    );
  }

  void _showPlayerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(recording.title,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Obx(() {
              final position = controller.currentPosition.value;
              final duration = controller.totalDuration.value;
              return Column(
                children: [
                  Slider(
                    value: position.inSeconds.toDouble(),
                    max: duration.inSeconds.toDouble(),
                    onChanged: (val) {
                      controller.seekTo(Duration(seconds: val.toInt()));
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(position.inSeconds)),
                        Text(_formatDuration(duration.inSeconds)),
                      ],
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  onPressed: () {
                    final newPos = controller.currentPosition.value -
                        const Duration(seconds: 10);
                    controller.seekTo(
                        newPos < Duration.zero ? Duration.zero : newPos);
                  },
                ),
                Obx(() => IconButton(
                      icon: Icon(
                        controller.isPlaying.value
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 64,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () {
                        if (controller.isPlaying.value) {
                          controller.pausePlayback();
                        } else {
                          controller.playRecording(recording);
                        }
                      },
                    )),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  onPressed: () {
                    final newPos = controller.currentPosition.value +
                        const Duration(seconds: 10);
                    controller.seekTo(newPos);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Speed: '),
                Obx(() => DropdownButton<double>(
                      value: controller.playbackSpeed.value,
                      items: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                        return DropdownMenuItem(
                          value: speed,
                          child: Text('${speed}x'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) controller.setPlaybackSpeed(val);
                      },
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
