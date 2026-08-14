import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fihirana/features/recording/domain/entities/user_recording.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
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
    final colors = Theme.of(context).colorScheme;
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
      child: Obx(() {
        final isMultiSelect = controller.isMultiSelectMode.value;
        final isSelected =
            controller.selectedRecordingIds.contains(recording.id);
        if (kDebugMode) {
          print(
              'RecordingTileWidget: Building tile for ${recording.id}, isMultiSelect=$isMultiSelect');
        }

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isMultiSelect) {
              if (kDebugMode) {
                print(
                    'RecordingTileWidget: Tapping in multi-select mode for recording: ${recording.id}');
              }
              controller.toggleRecordingSelection(recording.id);
            } else {
              controller.showPlayer(
                recording,
                isRecording: false,
                onStopRecording: () {},
              );
            }
          },
          onLongPress: () {
            if (!isMultiSelect) {
              controller.enableMultiSelectMode();
              controller.toggleRecordingSelection(recording.id);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primaryContainer
                  : colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? colors.primary : colors.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Checkbox for multi-select mode
                if (isMultiSelect)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        controller.toggleRecordingSelection(recording.id);
                      },
                      activeColor: colors.primary,
                    ),
                  ),

                // Icon
                RecordingTileIcon(
                  recording: recording,
                  isPublic: isPublic,
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: RecordingTileInfo(
                    recording: recording,
                    isPublic: isPublic,
                  ),
                ),

                // Menu (only show when not in multi-select mode)
                if (!isMultiSelect)
                  RecordingTileMenu(
                    recording: recording,
                    isPublic: isPublic,
                  ),
                // Temporary: always show menu for debugging
                if (isMultiSelect)
                  IconButton(
                    icon: Icon(Icons.more_vert, color: colors.onSurface),
                    onPressed: () {
                      if (kDebugMode) {
                        print(
                            'RecordingTileWidget: Menu button pressed in multi-select mode');
                      }
                      // Show a simple menu or force exit multi-select
                      controller.disableMultiSelectMode();
                    },
                  ),
              ],
            ),
          ),
        );
      }),
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
