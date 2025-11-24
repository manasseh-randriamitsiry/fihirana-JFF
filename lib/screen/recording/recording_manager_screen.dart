import 'package:fihirana/controller/recording_controller.dart';
import 'package:fihirana/controller/color_controller.dart';
import 'package:fihirana/controller/shell_controller.dart';
import 'package:fihirana/models/user_recording.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class RecordingManagerScreen extends StatelessWidget {
  const RecordingManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.put to ensure controller is initialized
    final RecordingController controller =
        Get.put(RecordingController(), permanent: true);
    final ColorController colorController = Get.find<ColorController>();
    
    // Auto-refresh when page is accessed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.onPageVisible();
    });
    
    // Auto-refresh when page is accessed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.onPageVisible();
    });

    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu_rounded, color: colorController.iconColor.value),
          onPressed: () => Get.find<ShellController>().toggleDrawer(),
        ),
        title: Text(
          'Recordings',
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: colorController.iconColor.value,
            ),
            tooltip: 'Refresh recordings',
            onPressed: () => controller.refreshRecordings(),
          ),
          Obx(() {
            if (controller.isDriveSignedIn.value) {
              return IconButton(
                icon: Icon(
                  Icons.cloud_done,
                  color: colorController.iconColor.value,
                ),
                tooltip: 'Signed in as ${controller.userEmail.value}',
                onPressed: () {
                  _showDriveDialog(context, controller, colorController);
                },
              );
            } else {
              return IconButton(
                icon: Icon(
                  Icons.cloud_upload_outlined,
                  color: colorController.iconColor.value,
                ),
                tooltip: 'Sign in to Google Drive',
                onPressed: () => controller.signInToDrive(),
              );
            }
          }),
        ],
      ),
      body: Obx(() {
        final personalRecordings = controller.recordings.where((r) => !r.isPublic).toList();
        final publicRecordings = controller.recordings.where((r) => r.isPublic).toList();
        
        // Debug: Print current state
        if (kDebugMode) {
          print('RecordingManager: Total recordings: ${controller.recordings.length}');
          print('RecordingManager: Personal: ${personalRecordings.length}, Public: ${publicRecordings.length}');
        }

        if (controller.recordings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mic_off_rounded,
                  size: 80,
                  color: colorController.iconColor.value.withValues(alpha: 0.3),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text(
                  'No recordings yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: colorController.textColor.value.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start recording your favorite hymns',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorController.textColor.value.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Actually refresh recordings
            await controller.refreshRecordings();
          },
          color: colorController.primaryColor.value,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _getItemCount(personalRecordings.length, publicRecordings.length),
            itemBuilder: (context, index) {
              return _buildItem(context, index, personalRecordings, publicRecordings, controller, colorController);
            },
          ),
        );
      }),
    );
  }

  int _getItemCount(int personalCount, int publicCount) {
    int count = 0;
    if (personalCount > 0) count += personalCount + 1; // +1 for header
    if (publicCount > 0) count += publicCount + 1; // +1 for header
    if (personalCount > 0 && publicCount > 0) count += 1; // +1 for spacing
    return count;
  }

  Widget _buildItem(BuildContext context, int index, List<UserRecording> personalRecordings, 
      List<UserRecording> publicRecordings, RecordingController controller, ColorController colorController) {
    final personalCount = personalRecordings.length;
    final publicCount = publicRecordings.length;
    
    // Determine if this index is a header or item
    int currentIndex = 0;
    
    // Personal recordings section
    if (personalCount > 0) {
      if (currentIndex == index) {
        return _buildSectionHeader('Personal Recordings', Icons.person, colorController, personalCount);
      }
      currentIndex++;
      
      if (index < currentIndex + personalCount) {
        final recordingIndex = index - currentIndex;
        final recording = personalRecordings[recordingIndex];
        return _RecordingTile(
          recording: recording,
          controller: controller,
          colorController: colorController,
          index: recordingIndex,
        );
      }
      currentIndex += personalCount;
    }
    
    // Spacing between sections
    if (personalCount > 0 && publicCount > 0) {
      if (currentIndex == index) {
        return const SizedBox(height: 16);
      }
      currentIndex++;
    }
    
    // Public recordings section
    if (publicCount > 0) {
      if (currentIndex == index) {
        return _buildSectionHeader('Public Recordings', Icons.public, colorController, publicCount);
      }
      currentIndex++;
      
      if (index < currentIndex + publicCount) {
        final recordingIndex = index - currentIndex;
        final recording = publicRecordings[recordingIndex];
        return _RecordingTile(
          recording: recording,
          controller: controller,
          colorController: colorController,
          index: recordingIndex + personalCount,
          isPublic: true,
        );
      }
    }
    
    // Fallback
    return const SizedBox.shrink();
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorController colorController, int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorController.primaryColor.value.withValues(alpha: 0.1),
            colorController.primaryColor.value.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorController.primaryColor.value.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorController.primaryColor.value,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorController.textColor.value,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$count recording${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: colorController.textColor.value.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideX(duration: 400.ms, begin: -0.1).fadeIn(duration: 400.ms);
  }

  void _showDriveDialog(BuildContext context, RecordingController controller, ColorController colorController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.cloud_done,
              color: colorController.primaryColor.value,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Google Drive',
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
              'Signed in as:',
              style: TextStyle(
                color: colorController.textColor.value.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              controller.userEmail.value ?? 'Unknown',
              style: TextStyle(
                color: colorController.textColor.value,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: colorController.textColor.value),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.signOutFromDrive();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorController.primaryColor.value,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
  final ColorController colorController;
  final int index;
  final bool isPublic;

  const _RecordingTile({
    required this.recording,
    required this.controller,
    required this.colorController,
    required this.index,
    this.isPublic = false,
  });

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colorController.backgroundColor.value,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorController.primaryColor.value.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPublic
                  ? [
                      Colors.orange,
                      Colors.orange.withValues(alpha: 0.7),
                    ]
                  : [
                      colorController.primaryColor.value,
                      colorController.primaryColor.value.withValues(alpha: 0.7),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  Icons.music_note_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              if (isPublic)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.public,
                      color: Colors.orange,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Text(
          recording.title,
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.music_video,
                  size: 12,
                  color: colorController.iconColor.value.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Hymn ${recording.hymnId} • ${_formatDuration(recording.durationSeconds)}',
                    style: TextStyle(
                      color: colorController.textColor.value.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: colorController.iconColor.value.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    DateFormat.yMMMd().add_jm().format(recording.createdAt),
                    style: TextStyle(
                      color: colorController.textColor.value.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Public indicator or Drive status
            if (isPublic)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.public,
                      size: 14,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Public',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else if (recording.driveFileId != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.cloud_done,
                  size: 18,
                  color: Colors.green,
                ),
              )
            else
              Obx(() {
                final isUploading = controller.isUploadingRecording(recording.id);
                final uploadError = controller.getUploadError(recording.id);
                
                if (isUploading) {
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.blue,
                        ),
                      ),
                    ),
                  );
                } else if (uploadError != null) {
                  return IconButton(
                    icon: Icon(
                      Icons.cloud_off,
                      color: Colors.red,
                    ),
                    onPressed: () => controller.retryUpload(recording),
                    tooltip: 'Upload failed. Tap to retry.\nError: $uploadError',
                  );
                } else {
                  return IconButton(
                    icon: Icon(
                      Icons.cloud_upload_outlined,
                      color: colorController.iconColor.value,
                    ),
                    onPressed: () => controller.uploadToDrive(recording),
                    tooltip: 'Upload to Drive',
                  );
                }
              }),
            
            // Menu button
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: colorController.iconColor.value,
              ),
              color: colorController.backgroundColor.value,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'share':
                    if (recording.driveWebLink != null) {
                      Share.share(
                          'Check out this recording: ${recording.driveWebLink}');
                    } else {
                      Share.shareXFiles([XFile(recording.filePath)],
                          text: recording.title);
                    }
                    break;
                  case 'download':
                    // For public recordings, add download option
                    if (isPublic) {
                      // Implement download functionality
                      Get.snackbar(
                        'Download',
                        'Download started',
                        backgroundColor: colorController.primaryColor.value.withValues(alpha: 0.8),
                        colorText: Colors.white,
                      );
                    }
                    break;
                  case 'delete':
                    if (!isPublic) {
                      _showDeleteConfirmation(context);
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(
                        Icons.share,
                        color: colorController.iconColor.value,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Share',
                        style: TextStyle(color: colorController.textColor.value),
                      ),
                    ],
                  ),
                ),
                if (isPublic)
                  PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        Icon(
                          Icons.download,
                          color: colorController.iconColor.value,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Download',
                          style: TextStyle(color: colorController.textColor.value),
                        ),
                      ],
                    ),
                  ),
                if (!isPublic)
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
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
    ).animate().slideX(
      duration: 300.ms,
      begin: index % 2 == 0 ? -0.1 : 0.1,
      curve: Curves.easeOut,
    ).fadeIn(duration: 300.ms);
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Recording',
              style: TextStyle(
                color: colorController.textColor.value,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${recording.title}"? This action cannot be undone.',
          style: TextStyle(color: colorController.textColor.value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorController.textColor.value),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteRecording(recording);
              Navigator.pop(context);
              Get.snackbar(
                'Deleted',
                'Recording deleted successfully',
                backgroundColor: Colors.red.withValues(alpha: 0.8),
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPlayerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorController.backgroundColor.value,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.4,
          maxChildSize: 0.7,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorController.iconColor.value.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Recording info
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorController.primaryColor.value,
                              colorController.primaryColor.value.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recording.title,
                              style: TextStyle(
                                color: colorController.textColor.value,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hymn ${recording.hymnId}',
                              style: TextStyle(
                                color: colorController.textColor.value.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Progress bar
                  Obx(() {
                    final position = controller.currentPosition.value;
                    final duration = controller.totalDuration.value;
                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: colorController.primaryColor.value,
                            inactiveTrackColor: colorController.iconColor.value.withValues(alpha: 0.2),
                            thumbColor: colorController.primaryColor.value,
                            overlayColor: colorController.primaryColor.value.withValues(alpha: 0.2),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble()),
                            max: duration.inSeconds.toDouble(),
                            onChanged: (val) {
                              controller.seekTo(Duration(seconds: val.toInt()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position.inSeconds),
                                style: TextStyle(
                                  color: colorController.textColor.value.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _formatDuration(duration.inSeconds),
                                style: TextStyle(
                                  color: colorController.textColor.value.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                  
                  const SizedBox(height: 24),
                  
                  // Playback controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Rewind 10 seconds
                      Container(
                        decoration: BoxDecoration(
                          color: colorController.primaryColor.value.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.replay_10,
                            color: colorController.primaryColor.value,
                            size: 28,
                          ),
                          onPressed: () {
                            final newPos = controller.currentPosition.value -
                                const Duration(seconds: 10);
                            controller.seekTo(
                                newPos < Duration.zero ? Duration.zero : newPos);
                          },
                        ),
                      ),
                      
                      // Play/Pause button
                      Obx(() => Container(
                        decoration: BoxDecoration(
                          color: colorController.primaryColor.value,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: colorController.primaryColor.value.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            controller.isPlaying.value
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                          onPressed: () {
                            if (controller.isPlaying.value) {
                              controller.pausePlayback();
                            } else {
                              controller.playRecording(recording);
                            }
                          },
                        ),
                      )),
                      
                      // Forward 10 seconds
                      Container(
                        decoration: BoxDecoration(
                          color: colorController.primaryColor.value.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.forward_10,
                            color: colorController.primaryColor.value,
                            size: 28,
                          ),
                          onPressed: () {
                            final newPos = controller.currentPosition.value +
                                const Duration(seconds: 10);
                            controller.seekTo(newPos);
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Speed control
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorController.primaryColor.value.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorController.primaryColor.value.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Playback Speed',
                          style: TextStyle(
                            color: colorController.textColor.value,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(() => Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                            final isSelected = controller.playbackSpeed.value == speed;
                            return InkWell(
                              onTap: () => controller.setPlaybackSpeed(speed),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? colorController.primaryColor.value 
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colorController.primaryColor.value,
                                  ),
                                ),
                                child: Text(
                                  '${speed}x',
                                  style: TextStyle(
                                    color: isSelected 
                                        ? Colors.white 
                                        : colorController.primaryColor.value,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}