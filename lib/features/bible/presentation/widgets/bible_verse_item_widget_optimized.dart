import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_controller.dart';

class BibleVerseItemWidget extends StatelessWidget {
  final int verseNumber;
  final String verseText;
  final VoidCallback onTap;

  const BibleVerseItemWidget({
    super.key,
    required this.verseNumber,
    required this.verseText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    
    return GetBuilder<BibleController>(
      id: 'verse_$verseNumber', // Unique ID for this specific verse
      builder: (controller) {
        final isSelected = controller.isVerseSelected(verseNumber);
        final isHighlighted = controller.isVerseHighlighted(verseNumber);
        final isSearchHighlighted = controller.isVerseSearchHighlighted(verseNumber);
        final isTargetVerse = verseNumber == controller.highlightedVerse.value;

        Color backgroundColor = Colors.transparent;
        if (isTargetVerse) {
          backgroundColor = Colors.orange.withValues(alpha: 0.4);
        } else if (isSearchHighlighted) {
          backgroundColor = Colors.yellow.withValues(alpha: 0.3);
        } else if (isHighlighted) {
          backgroundColor = Colors.blue.withValues(alpha: 0.2);
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              border: isSelected
                  ? Border.all(color: colorController.primaryColor.value)
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$verseNumber.',
                  style: TextStyle(
                    fontWeight: isTargetVerse
                        ? FontWeight.bold
                        : isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                    color: isTargetVerse
                        ? Colors.orange
                        : colorController.primaryColor.value,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    verseText,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      fontWeight: isTargetVerse
                          ? FontWeight.w600
                          : isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
                      color: isTargetVerse
                          ? Colors.orange.shade800
                          : isSelected
                              ? colorController.primaryColor.value
                              : colorController.textColor.value,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}