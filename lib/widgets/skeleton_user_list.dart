import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../controller/color_controller.dart';

class SkeletonUserList extends StatelessWidget {
  const SkeletonUserList({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorController colorController = Get.find();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      itemCount: 8, // Show enough items to fill the screen
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          color: colorController.backgroundColor.value,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Avatar, Name, Email
                Row(
                  children: [
                    // Avatar Skeleton
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorController.textColor.value.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and Email Skeletons
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name skeleton
                          Container(
                            width: 150,
                            height: 16,
                            decoration: BoxDecoration(
                              color: colorController.textColor.value.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Email skeleton
                          Container(
                            width: 200,
                            height: 13,
                            decoration: BoxDecoration(
                              color: colorController.textColor.value.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Divider skeleton
                Container(
                  height: 1,
                  color: colorController.textColor.value.withValues(alpha: 0.05),
                ),
                const SizedBox(height: 12),

                // Stats Row Skeleton
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Songs count skeleton
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colorController.textColor.value.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 60,
                          height: 13,
                          decoration: BoxDecoration(
                            color: colorController.textColor.value.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    // Last login skeleton
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colorController.textColor.value.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 80,
                          height: 13,
                          decoration: BoxDecoration(
                            color: colorController.textColor.value.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Divider skeleton
                Container(
                  height: 1,
                  color: colorController.textColor.value.withValues(alpha: 0.05),
                ),
                const SizedBox(height: 8),

                // Controls Row Skeleton
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Switch skeleton 1
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colorController.textColor.value.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 30,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colorController.textColor.value.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                    // Switch skeleton 2
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colorController.textColor.value.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 30,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colorController.textColor.value.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                    // Switch skeleton 3
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colorController.textColor.value.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 30,
                          height: 16,
                          decoration: BoxDecoration(
                            color: colorController.textColor.value.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ],
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
            .fadeIn(duration: 600.ms, delay: Duration(milliseconds: 50 * index), curve: Curves.easeOut);
      },
    );
  }
}