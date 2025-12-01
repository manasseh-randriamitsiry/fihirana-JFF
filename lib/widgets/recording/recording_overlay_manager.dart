import 'package:fihirana/widgets/player/recording_mini_player.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/recording_controller.dart';
import 'recording_overlay.dart';

class RecordingOverlayManager extends StatelessWidget {
  const RecordingOverlayManager({super.key});

  @override
  Widget build(BuildContext context) {
    // Get controller inside build to avoid calling Get.put during widget creation
    final RecordingController controller = Get.find<RecordingController>();

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
  }

  // Static method to show recording overlay from anywhere
  static void showRecordingOverlay(String hymnId, String hymnTitle) {
    final controller = Get.find<RecordingController>();
    controller.showOverlay(hymnId, hymnTitle);
  }

  // Static method to check if overlay is visible
  static bool isOverlayVisible() {
    final controller = Get.find<RecordingController>();
    return controller.shouldShowOverlay();
  }

  // Static method to restore overlay if minimized
  static void restoreOverlay() {
    final controller = Get.find<RecordingController>();
    controller.restoreOverlay();
  }
}
