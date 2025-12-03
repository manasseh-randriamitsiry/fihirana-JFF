import 'package:fihirana/features/audio/presentation/widgets/recording_mini_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'recording_overlay.dart';

class RecordingOverlayManager extends GetView<RecordingController> {
  const RecordingOverlayManager({super.key});

  @override
  Widget build(BuildContext context) {
    // Use GetView's controller property instead of Get.put
    // This prevents calling Get.put during build
    return GetBuilder<RecordingController>(
      init: RecordingController(),
      builder: (controller) {
        return Obx(() {
          // Early return for better performance
          if (!controller.overlayVisible.value) {
            return const SizedBox.shrink();
          }

          // Show mini player if overlay is minimized
          if (controller.isOverlayMinimized.value) {
            return const RecordingMiniPlayer();
          }

          // Show full overlay if visible and not minimized
          return RecordingOverlay(
            hymnId: controller.currentHymnId.value,
            hymnTitle: controller.currentHymnTitle.value,
            onClose: () => controller.hideOverlay(),
            onMinimize: () => controller.minimizeOverlay(),
          );
        });
      },
    );
  }

  // Static method to show recording overlay from anywhere
  static void showRecordingOverlay(String hymnId, String hymnTitle) {
    final controller = Get.put(RecordingController());
    controller.showOverlay(hymnId, hymnTitle);
  }

  // Static method to check if overlay is visible
  static bool isOverlayVisible() {
    final controller = Get.put(RecordingController());
    return controller.shouldShowOverlay();
  }

  // Static method to restore overlay if minimized
  static void restoreOverlay() {
    final controller = Get.put(RecordingController());
    controller.restoreOverlay();
  }
}
