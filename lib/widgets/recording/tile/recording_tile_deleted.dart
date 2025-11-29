import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../models/user_recording.dart';
import '../../../controller/color_controller.dart';

class RecordingTileDeleted extends StatelessWidget {
  final UserRecording recording;
  final int index;
  final VoidCallback? onRestore;
  final VoidCallback? onPermanentDelete;
  final ColorController colorController = Get.find<ColorController>();

  RecordingTileDeleted({
    super.key,
    required this.recording,
    required this.index,
    this.onRestore,
    this.onPermanentDelete,
  });

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorController.backgroundColor.value,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        dense: true,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.grey,
                Colors.grey.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                recording.title,
                style: TextStyle(
                  color: colorController.textColor.value.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'DELETED',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 10,
              color: colorController.textColor.value.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 4),
            Text(
              _formatDuration(recording.durationSeconds),
              style: TextStyle(
                color: colorController.textColor.value.withValues(alpha: 0.3),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•',
              style: TextStyle(
                color: colorController.textColor.value.withValues(alpha: 0.3),
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                DateFormat.yMMMd().format(recording.createdAt),
                style: TextStyle(
                  color: colorController.textColor.value.withValues(alpha: 0.3),
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: colorController.iconColor.value.withValues(alpha: 0.7),
            size: 20,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          color: colorController.backgroundColor.value,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            switch (value) {
              case 'restore':
                onRestore?.call();
                break;
              case 'permanent_delete':
                onPermanentDelete?.call();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'restore',
              height: 40,
              child: Row(
                children: [
                  const Icon(
                    Icons.restore,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Restore',
                    style: TextStyle(
                        color: colorController.textColor.value, fontSize: 13),
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'permanent_delete',
              height: 40,
              child: Row(
                children: [
                  Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                    size: 18,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Delete Permanently',
                    style: TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideX(
          duration: 300.ms,
          begin: index % 2 == 0 ? -0.1 : 0.1,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 300.ms);
  }
}
