import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';

/// Skeleton loader for hymn detail screen
/// Shows a static skeleton while the hymn data is loading.
class HymnDetailSkeleton extends StatelessWidget {
  final double fontSize;
  final double countFontSize;

  const HymnDetailSkeleton({
    super.key,
    this.fontSize = AppDimensions.fontMd,
    this.countFontSize = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ColorController>(
      builder: (controller) {
        final skeletonColor =
            controller.textColor.value.withValues(alpha: 0.08);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.fontMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hymn number badge skeleton
              Center(
                child: Container(
                  width: 80,
                  height: 40,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Hymn title skeleton
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: fontSize * 1.5,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Second line of title (for long titles)
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: fontSize * 1.5,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Bridge section skeleton
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: skeletonColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: fontSize,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: fontSize,
                      decoration: BoxDecoration(
                        color: skeletonColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Verse content skeleton
              ...List.generate(
                  3,
                  (verseIndex) => Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Verse number
                            Row(
                              children: [
                                Container(
                                  width: countFontSize,
                                  height: countFontSize,
                                  decoration: BoxDecoration(
                                    color: skeletonColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Verse lines
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: List.generate(
                                        4,
                                        (lineIndex) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8),
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    (0.6 +
                                                        (lineIndex % 3) * 0.1),
                                                height: fontSize,
                                                decoration: BoxDecoration(
                                                  color: skeletonColor,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            )),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )),
            ],
          ),
        );
      },
    );
  }
}
