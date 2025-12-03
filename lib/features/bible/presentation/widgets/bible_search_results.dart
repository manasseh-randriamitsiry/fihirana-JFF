import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'bible_search_result_item.dart';

class BibleSearchResults extends StatelessWidget {
  final double fontSize;

  const BibleSearchResults({
    super.key,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final bibleController = Get.find<BibleController>();

    return Container(
      margin: const EdgeInsets.all(20),
      child: Obx(() {
        if (bibleController.isSearching.value) {
          return _buildLoadingWidget(context, colorController);
        }

        if (bibleController.searchQuery.value.isEmpty) {
          return _buildEmptySearchWidget(context, colorController);
        }

        if (bibleController.searchResults.isEmpty) {
          return _buildNoResultsWidget(context, colorController);
        }

        return _buildResultsList(context, bibleController);
      }),
    );
  }

  Widget _buildLoadingWidget(BuildContext context, ColorController colorController) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorController.primaryColor.value,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.search,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: colorController.textColor.value.withValues(alpha: 0.7),
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchWidget(BuildContext context, ColorController colorController) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 64,
            color: colorController.textColor.value.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.enterWordToSearch,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: colorController.textColor.value.withValues(alpha: 0.5),
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsWidget(BuildContext context, ColorController colorController) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: colorController.textColor.value.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noSearchResults,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: colorController.textColor.value.withValues(alpha: 0.7),
              fontSize: fontSize,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.changeWordToSearch,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: colorController.textColor.value.withValues(alpha: 0.5),
              fontSize: fontSize * 0.9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, BibleController bibleController) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: bibleController.searchResults.length,
      itemBuilder: (context, index) {
        final result = bibleController.searchResults[index];
        return BibleSearchResultItem(
          result: result,
          fontSize: fontSize,
        );
      },
    );
  }
}