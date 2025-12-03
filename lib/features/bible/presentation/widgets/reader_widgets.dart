import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/features/bible/presentation/controllers/bible_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class BibleVerseItemWidget extends StatelessWidget {
  final int verseNumber;
  final String verseText;
  final double fontSize;
  final TextStyle verseStyle;

  const BibleVerseItemWidget({
    super.key,
    required this.verseNumber,
    required this.verseText,
    required this.fontSize,
    required this.verseStyle,
  });

  @override
  Widget build(BuildContext context) {
    final bibleController = Get.find<BibleController>();
    final colorController = Get.find<ColorController>();

    return Obx(() {
      final isSelected = bibleController.isVerseSelected(verseNumber);
      final isHighlighted = bibleController.isVerseHighlighted(verseNumber);
      final isSearchHighlighted =
          bibleController.isVerseSearchHighlighted(verseNumber);

      Color backgroundColor = Colors.transparent;
      if (isSearchHighlighted) {
        backgroundColor = Colors.yellow.withValues(alpha: 0.3);
      } else if (isSelected) {
        backgroundColor =
            colorController.primaryColor.value.withValues(alpha: 0.15);
      } else if (isHighlighted) {
        backgroundColor =
            colorController.primaryColor.value.withValues(alpha: 0.05);
      }

      return GestureDetector(
        onTap: () => bibleController.toggleVerseSelection(verseNumber),
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
                    fontSize: fontSize * 0.7,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.superscripts()],
                  ),
                ),
                TextSpan(
                  text: verseText,
                  style: verseStyle,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class ChapterNavigationWidget extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Color textColor;

  const ChapterNavigationWidget({
    super.key,
    required this.onPrevious,
    required this.onNext,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: onPrevious,
            icon: const Icon(Icons.arrow_back_rounded),
            label: Text(l10n.previous),
            style: TextButton.styleFrom(
              foregroundColor: textColor,
            ),
          ),
          TextButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(l10n.next),
            style: TextButton.styleFrom(
              foregroundColor: textColor,
            ),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }
}