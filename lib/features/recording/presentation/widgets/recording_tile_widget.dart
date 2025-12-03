import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'tile/recording_tile_icon.dart';
import 'tile/recording_tile_info.dart';
import 'tile/recording_tile_menu.dart';
import 'tile/recording_tile_deleted.dart';

class RecordingTileWidget extends StatelessWidget {
  final UserRecording recording;
  final int index;
  final bool isPublic;
  final bool isDeleted;
  final VoidCallback? onRestore;
  final VoidCallback? onPermanentDelete;
  final RecordingController controller = Get.find<RecordingController>();
  final ColorController colorController = Get.find<ColorController>();

  RecordingTileWidget({
    super.key,
    required this.recording,
    required this.index,
    this.isPublic = false,
    this.isDeleted = false,
    this.onRestore,
    this.onPermanentDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isDeleted) {
      return RecordingTileDeleted(
        recording: recording,
        index: index,
        onRestore: onRestore,
        onPermanentDelete: onPermanentDelete,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          controller.showPlayer(
            recording,
            isRecording: false,
            onStopRecording: () {},
          );
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorController.backgroundColor.value,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorController.textColor.value.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              RecordingTileIcon(
                recording: recording,
                isPublic: isPublic,
              ),
              const SizedBox(width: 16),

              // Info
              RecordingTileInfo(
                recording: recording,
                isPublic: isPublic,
              ),

              // Menu
              RecordingTileMenu(
                recording: recording,
                isPublic: isPublic,
              ),
            ],
          ),
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
