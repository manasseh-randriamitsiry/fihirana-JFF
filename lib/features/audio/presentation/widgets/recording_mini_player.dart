import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';

class RecordingMiniPlayer extends StatelessWidget {
  const RecordingMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final RecordingController controller = Get.find<RecordingController>();
    final ColorController colorController = Get.find<ColorController>();

    return Positioned(
      bottom: 20,
      right: 20,
      child: Obx(() {
        if (!controller.shouldShowOverlay() ||
            !controller.isOverlayMinimized.value) {
          return const SizedBox.shrink();
        }

        return Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorController.primaryColor.value,
                  colorController.primaryColor.value.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => controller.restoreOverlay(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Recording indicator
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true))
                        .scale(
                          duration: 1000.ms,
                          curve: Curves.easeInOut,
                        ),

                    const SizedBox(width: 12),

                    // Recording info
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.currentHymnTitle.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Hymn ${controller.currentHymnId.value}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    // Timer
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Obx(() => Text(
                            _formatDuration(controller.recordDuration.value),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          )),
                    ),

                    const SizedBox(width: 8),

                    // Expand icon
                    const Icon(
                      Icons.open_in_full,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            .animate()
            .slideY(
              duration: 300.ms,
              begin: 1.0,
              curve: Curves.easeOut,
            )
            .fadeIn(duration: 300.ms);
      }),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
