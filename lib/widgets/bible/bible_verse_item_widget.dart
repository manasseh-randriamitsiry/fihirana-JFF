import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../controller/bible_controller.dart';

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
        backgroundColor = colorController.primaryColor.value.withValues(alpha: 0.05);
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