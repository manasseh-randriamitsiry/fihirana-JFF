import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_search_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/components/app_state_view.dart';
import 'bible_search_result_item.dart';

class BibleSearchResults extends StatelessWidget {
  const BibleSearchResults({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final search = Get.find<BibleSearchController>();

    return Obx(() {
      final query = search.searchQuery.value.trim();
      final results = search.searchResults;

      if (query.isEmpty) {
        return AppStateView(
          state: AppState.empty,
          emptyTitle: l10n.enterWordToSearch,
          emptyMessage: l10n.searchWordsOrVersesHint,
          emptyIcon: Icons.search_rounded,
          child: const SizedBox.shrink(),
        );
      }

      if (results.isEmpty) {
        return AppStateView(
          state: AppState.empty,
          emptyTitle: l10n.noSearchResults,
          emptyMessage: l10n.changeWordToSearch,
          emptyIcon: Icons.search_off_rounded,
          child: const SizedBox.shrink(),
        );
      }

      return AppStateView(
        state: search.isSearching.value ? AppState.loading : AppState.full,
        skeletonRows: 5,
        emptyTitle: l10n.noSearchResults,
        child: ListView.separated(
          key: const PageStorageKey('bible_search_results_list'),
          padding: const EdgeInsets.all(AppScale.gutter),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppScale.space8),
          itemBuilder: (context, index) => BibleSearchResultItem(
            // The reference, not the words: the corpus repeats verse text.
            key: ValueKey(results[index].listKey),
            result: results[index],
          ),
        ),
      );
    });
  }
}
