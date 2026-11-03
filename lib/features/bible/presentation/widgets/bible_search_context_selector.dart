import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_book_controller.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_search_controller.dart';
import 'package:fihirana/features/bible/domain/entities/bible_search.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';

/// Where a word is looked for. The chips show the scope the search actually ran
/// in, so a row of results can never disagree with the control above it: the
/// chapter chip only exists while the reader sits on a chapter, and the
/// controller falls back to the whole Bible when it does not.
class BibleSearchContextSelector extends StatelessWidget {
  const BibleSearchContextSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final search = Get.find<BibleSearchController>();
    final chapter = Get.find<BibleBookController>().selectedChapter.value;

    return Obx(() {
      final active = search.activeSearchContext;
      final inChapter = active == BibleSearchContext.currentChapter;

      return Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppScale.gutter, vertical: AppScale.space8),
        child: Wrap(
          spacing: AppScale.space8,
          runSpacing: AppScale.space8,
          children: [
            _scopeChip(
              context: context,
              label: l10n.searchBooks,
              selected: active == BibleSearchContext.books,
              onTap: () => _select(BibleSearchContext.books),
            ),
            if (inChapter)
              _scopeChip(
                context: context,
                label: l10n.searchCurrentChapter(chapter),
                selected: true,
                onTap: () => _select(BibleSearchContext.currentChapter),
              ),
            _scopeChip(
              context: context,
              label: l10n.searchEntireBible,
              selected: active == BibleSearchContext.allBible,
              onTap: () => _select(BibleSearchContext.allBible),
            ),
          ],
        ),
      );
    });
  }

  void _select(BibleSearchContext searchContext) {
    final search = Get.find<BibleSearchController>();
    search.setSearchContext(searchContext);
    // The same word in a new scope is a new search, so it runs again.
    search.performSearch();
  }

  Widget _scopeChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final s = AppSurfaces.of(context);
    final type = Theme.of(context).textTheme;
    return ChoiceChip(
      // The fill alone does not read as chosen on a tinted paper, so the chosen
      // scope takes the accent the way a chosen register row does.
      label: Text(label,
          style:
              type.labelMedium?.copyWith(color: selected ? s.accent : s.ink)),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
