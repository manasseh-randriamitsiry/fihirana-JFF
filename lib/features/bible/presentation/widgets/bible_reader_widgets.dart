import 'package:flutter/material.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/app_typography.dart';

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
    final AppSurfaces s = AppSurfaces.of(context);
    final l10n = AppLocalizations.of(context);

    return AppListRow(
      icon: Icons.menu_book_outlined,
      iconColor: s.accent,
      title: bookName,
      subtitle: l10n.chaptersCount(chapterCount),
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppScale.space8, vertical: AppScale.space4),
            decoration: BoxDecoration(
              color: s.accentSoft,
              borderRadius: BorderRadius.circular(AppScale.radiusControl),
            ),
            child: Text(
              '$chapterCount',
              style: AppTypography.figure(s,
                  size: 13, weight: FontWeight.w700, color: s.accent),
            ),
          ),
          const SizedBox(width: AppScale.space4),
          Icon(Icons.chevron_right_rounded, color: s.muted),
        ],
      ),
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
    final AppSurfaces s = AppSurfaces.of(context);
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 360 ? 4 : 5;
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppScale.gutter, AppScale.gutter,
              AppScale.gutter, AppScale.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    left: AppScale.space4, bottom: AppScale.space8),
                child: Text(
                  l10n.chaptersCount(chapters.length),
                  style: AppTypography.figure(s, size: 13, color: s.muted),
                ),
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: s.paper,
                    borderRadius: BorderRadius.circular(AppScale.radiusSurface),
                    border: Border.all(color: s.rule, width: AppScale.ruleHair),
                  ),
                  child: GridView.builder(
                    key: const PageStorageKey('bible_chapter_grid'),
                    padding: const EdgeInsets.all(AppScale.space12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppScale.space8,
                      mainAxisSpacing: AppScale.space8,
                      childAspectRatio: 1.08,
                    ),
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = chapters[index];
                      return Material(
                        color: Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppScale.radiusControl),
                        child: InkWell(
                          onTap: () => onChapterSelected(chapter),
                          borderRadius:
                              BorderRadius.circular(AppScale.radiusControl),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: s.sheet,
                              borderRadius:
                                  BorderRadius.circular(AppScale.radiusControl),
                              border: Border.all(
                                  color: s.rule, width: AppScale.ruleHair),
                            ),
                            child: Center(
                              child: Text('$chapter',
                                  style: AppTypography.figure(s,
                                      size: AppTypography.headSize(16))),
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
    final AppSurfaces s = AppSurfaces.of(context);
    final bool isTargetVerse = verseNumber == highlightedVerse;

    // A plain verse is running text: no box around every line of a chapter.
    // Only a marked verse earns a surface, and each mark reads differently.
    final Color fill = isSelected
        ? s.accentSoft
        : isHighlighted
            ? s.paper2
            : isSearchHighlighted
                ? s.paper3
                : Colors.transparent;
    final Color? bar =
        isSelected ? s.accent : (isHighlighted ? s.ruleFirm : null);
    final Color numberColor = isSelected || isTargetVerse ? s.accent : s.muted;

    return Semantics(
      button: true,
      label: AppLocalizations.of(context).verseWithNumber(verseNumber),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppScale.space8),
        child: Ink(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(AppScale.radiusRow),
            border: isTargetVerse
                ? Border.all(color: s.accent, width: AppScale.ruleHair)
                : null,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppScale.radiusRow),
            child: Stack(
              children: [
                if (bar != null)
                  Positioned(
                    left: 0,
                    top: AppScale.space12,
                    bottom: AppScale.space12,
                    child: SizedBox(
                      width: AppScale.ruleBar,
                      child: ColoredBox(color: bar),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppScale.space16,
                      AppScale.space12, AppScale.space16, AppScale.space12),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$verseNumber ',
                          style: AppTypography.figure(
                            s,
                            size: fontSize * .7,
                            weight: FontWeight.w700,
                            color: numberColor,
                          ).copyWith(
                            fontFeatures: const [FontFeature.superscripts()],
                          ),
                        ),
                        TextSpan(
                          text: verseText,
                          style: verseStyle.copyWith(
                            color: isSelected ? s.ink : s.ink2,
                            fontWeight: isTargetVerse
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
      padding: const EdgeInsets.only(
          top: AppScale.space16, bottom: AppScale.space40),
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
          const SizedBox(width: AppScale.space12),
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
