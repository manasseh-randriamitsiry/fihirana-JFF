import 'package:flutter/material.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

class BibleBookItemWidget extends StatelessWidget {
  final String bookName;
  final int chapterCount;
  final VoidCallback onTap;
  final bool showDivider;

  const BibleBookItemWidget({
    super.key,
    required this.bookName,
    required this.chapterCount,
    required this.onTap,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppListRow(
          icon: Icons.menu_book_outlined,
          iconColor: colors.primary,
          title: bookName,
          subtitle: l10n.chaptersCount(chapterCount),
          onTap: onTap,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$chapterCount',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
        if (showDivider) const AppGroupDivider(),
      ],
    );
  }
}

class BibleChapterGridWidget extends StatelessWidget {
  final List<int> chapters;
  final ValueChanged<int> onChapterSelected;

  const BibleChapterGridWidget({
    super.key,
    required this.chapters,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 360 ? 4 : 5;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  l10n.chaptersCount(chapters.length),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        letterSpacing: .2,
                      ),
                ),
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: .65),
                    ),
                  ),
                  child: GridView.builder(
                    key: const PageStorageKey('bible_chapter_grid'),
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.08,
                    ),
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = chapters[index];
                      return Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => onChapterSelected(chapter),
                          borderRadius: BorderRadius.circular(12),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    colors.outlineVariant.withValues(alpha: .7),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$chapter',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: colors.onSurface),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
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
    final hasEmphasis =
        isTargetVerse || isSearchHighlighted || isSelected || isHighlighted;

    Color backgroundColor = colors.surface;
    Color foregroundColor = colors.onSurface;
    Color verseNumberColor = colors.primary;
    if (isTargetVerse) {
      backgroundColor = colors.secondaryContainer;
      foregroundColor = colors.onSecondaryContainer;
      verseNumberColor = colors.onSecondaryContainer;
    } else if (isSearchHighlighted) {
      backgroundColor = colors.tertiaryContainer;
      foregroundColor = colors.onTertiaryContainer;
      verseNumberColor = colors.onTertiaryContainer;
    } else if (isSelected) {
      backgroundColor = colors.primaryContainer;
      foregroundColor = colors.onPrimaryContainer;
      verseNumberColor = colors.onPrimaryContainer;
    } else if (isHighlighted) {
      backgroundColor = colors.secondaryContainer;
      foregroundColor = colors.onSecondaryContainer;
      verseNumberColor = colors.onSecondaryContainer;
    }

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).verseWithNumber(verseNumber),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? colors.primary
                    : colors.outlineVariant.withValues(
                        alpha: hasEmphasis ? .8 : .55,
                      ),
                width: isSelected ? 1.4 : 1,
              ),
            ),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$verseNumber ',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: verseNumberColor,
                      fontSize: fontSize * .72,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.superscripts()],
                    ),
                  ),
                  TextSpan(
                    text: verseText,
                    style: verseStyle.copyWith(
                      color: foregroundColor,
                      fontWeight:
                          isTargetVerse ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.only(top: 14, bottom: 32),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onPrevious,
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(l10n.previous),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(l10n.next),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.onSurface,
              ),
              iconAlignment: IconAlignment.end,
            ),
          ),
        ],
      ),
    );
  }
}
