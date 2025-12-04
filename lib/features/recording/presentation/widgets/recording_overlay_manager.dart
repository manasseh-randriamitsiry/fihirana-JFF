import 'package:fihirana/features/audio/presentation/widgets/recording_mini_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/features/recording/di/recording_di.dart';
import 'package:fihirana/features/recording/domain/repositories/recording_repository.dart';
import 'recording_overlay.dart';

class RecordingOverlayManager extends StatelessWidget {
  const RecordingOverlayManager({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure dependencies are available before building
    if (!Get.isRegistered<RecordingRepository>(tag: 'recordingRepository')) {
      return const SizedBox.shrink();
    }

    // Get the controller after checking dependencies
    final controller = RecordingDI.recordingController;

    return GetBuilder<RecordingController>(
      init: controller,
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
    try {
      final controller = RecordingDI.recordingController;
      controller.showOverlay(hymnId, hymnTitle);
    } catch (e) {
      if (kDebugMode) print('Error accessing recording controller: $e');
      // Initialize dependencies if not available
      if (!Get.isRegistered<RecordingRepository>(tag: 'recordingRepository')) {
        RecordingDI.initialize();
        final controller = RecordingDI.recordingController;
        controller.showOverlay(hymnId, hymnTitle);
      }
    }
  }

  // Static method to check if overlay is visible
  static bool isOverlayVisible() {
    try {
      final controller = RecordingDI.recordingController;
      return controller.shouldShowOverlay();
    } catch (e) {
      if (kDebugMode) print('Error accessing recording controller: $e');
      return false;
    }
  }

  // Static method to restore overlay if minimized
  static void restoreOverlay() {
    try {
      final controller = RecordingDI.recordingController;
      controller.restoreOverlay();
    } catch (e) {
      if (kDebugMode) print('Error accessing recording controller: $e');
    }
  }
}
