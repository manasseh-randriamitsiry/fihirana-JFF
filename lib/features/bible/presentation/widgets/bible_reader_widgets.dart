import 'package:flutter/material.dart';
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
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          bookName,
          style: TextStyle(
            fontFamily: 'Roboto',
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$chapterCount',
            style: TextStyle(
              color: colors.onPrimaryContainer,
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
    final colors = Theme.of(context).colorScheme;

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
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.outlineVariant,
              ),
            ),
            child: Center(
              child: Text(
                '$chapter',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: colors.onPrimaryContainer,
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
  final int highlightedVerse;
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
    required this.highlightedVerse,
    required this.isSelected,
    required this.isHighlighted,
    required this.isSearchHighlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isTargetVerse = verseNumber == highlightedVerse;

    Color backgroundColor = Colors.transparent;
    if (isTargetVerse) {
      backgroundColor = colors.secondaryContainer;
    } else if (isSearchHighlighted) {
      backgroundColor = colors.tertiaryContainer;
    } else if (isSelected) {
      backgroundColor = colors.primaryContainer;
    } else if (isHighlighted) {
      backgroundColor = colors.secondaryContainer;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: colors.primary,
                  width: 1.2,
                )
              : Border.all(
                  color: Colors.transparent,
                ),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$verseNumber ',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: isTargetVerse ? colors.secondary : colors.primary,
                  fontSize: fontSize * 0.7,
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.superscripts()],
                ),
              ),
              TextSpan(
                text: verseText,
                style: isTargetVerse
                    ? verseStyle.copyWith(
                        color: colors.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      )
                    : verseStyle,
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
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

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
              foregroundColor: colors.onSurface,
            ),
          ),
          TextButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(l10n.next),
            style: TextButton.styleFrom(
              foregroundColor: colors.onSurface,
            ),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }
}
