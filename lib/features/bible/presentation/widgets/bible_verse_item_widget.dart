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

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.yellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final bibleController = Get.find<BibleController>();
    
    return Obx(() {
      final isSelected = bibleController.isVerseSelected(verseNumber);
      final isHighlighted = bibleController.isVerseHighlighted(verseNumber);
      final isSearchHighlighted = bibleController.isVerseSearchHighlighted(verseNumber);

      Color backgroundColor = Colors.transparent;
      if (isSearchHighlighted) {
        backgroundColor = Colors.yellow.withValues(alpha: 0.3);
      } else if (isSelected) {
        backgroundColor = colorController.primaryColor.value.withValues(alpha: 0.15);
      } else if (isHighlighted) {
        // Get the actual highlight to use its color
        final highlight = bibleController.getHighlightForVerse(verseNumber);
        if (highlight != null) {
          final highlightColor = _getColorFromString(highlight.color);
          backgroundColor = highlightColor.withValues(alpha: 0.3);
        } else {
          backgroundColor = Colors.yellow.withValues(alpha: 0.3);
        }
      }

      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$verseNumber ',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: colorController.primaryColor.value,
                    fontSize: 16, // Will be overridden by parent
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.superscripts()],
                  ),
                ),
                TextSpan(
                  text: verseText,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    color: colorController.textColor.value,
                    fontSize: 16, // Will be overridden by parent
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}