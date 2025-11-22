import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../controller/color_controller.dart';

class SkeletonHymnList extends StatelessWidget {
  const SkeletonHymnList({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorController colorController = Get.find();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: colorController.backgroundColor.value,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorController.backgroundColor.value,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorController.textColor.value.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    // Circle Avatar Skeleton
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: colorController.textColor.value.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Text Skeletons
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Container(
                            width: double.infinity,
                            height: 16,
                            decoration: BoxDecoration(
                              color: colorController.textColor.value
                                  .withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Subtitle
                          Container(
                            width: 150,
                            height: 12,
                            decoration: BoxDecoration(
                              color: colorController.textColor.value
                                  .withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Trailing Icon Skeleton
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colorController.textColor.value.withValues(alpha:0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(
                    duration: 1200.ms,
                    color: colorController.textColor.value.withValues(alpha:0.05))
                .animate() // Separate animation for fade in
                .fadeIn(duration: 600.ms, curve: Curves.easeOut),
          );
        },
        childCount: 8, // Show enough items to fill the screen
      ),
    );
  }
}
