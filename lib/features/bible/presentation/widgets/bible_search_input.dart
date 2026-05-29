import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';

/// Search input for the Bible search dialog.
///
/// Changes to the text field are forwarded to [BibleController.searchQuery]
/// and [BibleController.performSearch].  The controller itself applies a
/// 500 ms debounce for expensive (allBible) searches, so it is safe to call
/// [performSearch] on every keystroke here.
class BibleSearchInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final double fontSize;

  const BibleSearchInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorController = Get.find<ColorController>();
    final bibleController = Get.find<BibleController>();

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorController.primaryColor.value.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorController.primaryColor.value.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyle(
          fontFamily: 'Roboto',
          color: colorController.textColor.value,
          fontSize: fontSize,
        ),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: l10n.searchWordsOrVersesHint,
          hintStyle: TextStyle(
            fontFamily: 'Roboto',
            color: colorController.textColor.value.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colorController.iconColor.value,
          ),
          suffixIcon: Obx(() {
            if (bibleController.searchQuery.value.isNotEmpty) {
              return IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: colorController.iconColor.value,
                ),
                onPressed: () {
                  controller.clear();
                  bibleController.updateSearchQuery('');
                },
              );
            }
            return const SizedBox.shrink();
          }),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        onChanged: (value) {
          bibleController.searchQuery.value = value;
          bibleController.performSearch();
        },
        // Pressing the keyboard "Search" button triggers an immediate search
        // (bypassing the debounce for faster UX on explicit user intent).
        onSubmitted: (value) {
          bibleController.searchQuery.value = value;
          bibleController.performSearch();
        },
      ),
    );
  }
}