import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class BibleBookItemWidget extends StatelessWidget {
  final String bookName;
  final int chapterCount;
  final VoidCallback onTap;

  const BibleBookItemWidget({
    super.key,
    required this.bookName,
    required this.chapterCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorController.primaryColor.value.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          bookName,
          style: TextStyle(
            fontFamily: 'Roboto',
            color: colorController.textColor.value,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colorController.primaryColor.value.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$chapterCount',
            style: TextStyle(
              color: colorController.primaryColor.value,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class BibleChapterGridWidget extends StatelessWidget {
  final List<int> chapters;
  final Function(int) onChapterSelected;

  const BibleChapterGridWidget({
    super.key,
    required this.chapters,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return InkWell(
          onTap: () => onChapterSelected(chapter),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: colorController.primaryColor.value.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorController.primaryColor.value.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Text(
                '$chapter',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: colorController.primaryColor.value,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BibleVerseItemWidget extends StatelessWidget {
  final int verseNumber;
  final String verseText;
  final TextStyle verseStyle;
  final double fontSize;
  final bool isSelected;
  final bool isHighlighted;
  final bool isSearchHighlighted;
  final VoidCallback onTap;

  const BibleVerseItemWidget({
    super.key,
    required this.verseNumber,
    required this.verseText,
    required this.verseStyle,
    required this.fontSize,
    required this.isSelected,
    required this.isHighlighted,
    required this.isSearchHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    
    Color backgroundColor = Colors.transparent;
    if (isSearchHighlighted) {
      backgroundColor = Colors.yellow.withValues(alpha: 0.3);
    } else if (isSelected) {
      backgroundColor = colorController.primaryColor.value.withValues(alpha: 0.15);
    } else if (isHighlighted) {
      // Use yellow for saved highlights
      backgroundColor = Colors.yellow.withValues(alpha: 0.3);
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
  }
}

class BibleChapterNavigationWidget extends StatelessWidget {
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const BibleChapterNavigationWidget({
    super.key,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorController = Get.find<ColorController>();
    
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
              foregroundColor: colorController.textColor.value,
            ),
          ),
          TextButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(l10n.next),
            style: TextButton.styleFrom(
              foregroundColor: colorController.textColor.value,
            ),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }
}