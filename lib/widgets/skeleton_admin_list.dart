import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../controller/color_controller.dart';

class SkeletonAdminList extends StatelessWidget {
  const SkeletonAdminList({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorController colorController = Get.find();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 8, // Show enough items to fill the screen
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: colorController.backgroundColor.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Checkbox Skeleton
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorController.textColor.value.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and Subtitle Skeletons
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title skeleton
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colorController.textColor.value.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Subtitle skeleton 1
                        Container(
                          width: 180,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colorController.textColor.value.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Subtitle skeleton 2
                        Container(
                          width: 120,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colorController.textColor.value.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Date skeleton
                        Container(
                          width: 100,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colorController.textColor.value.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                  duration: 1200.ms,
                  color: colorController.textColor.value.withValues(alpha: 0.05))
              .animate() // Separate animation for fade in
              .fadeIn(duration: 600.ms, delay: Duration(milliseconds: 50 * index), curve: Curves.easeOut),
        );
      },
    );
  }
}