import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class BibleSelectionActionBarWidget extends StatelessWidget {
  const BibleSelectionActionBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final bibleController = Get.find<BibleController>();
    final l10n = AppLocalizations.of(context)!;

    return Obx(() {
      if (!bibleController.isSelecting) {
        return const SizedBox.shrink();
      }

      return Positioned(
        bottom: 24,
        left: 24,
        right: 24,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: colorController.backgroundColor.value,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: colorController.primaryColor.value.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Clear Selection
              IconButton(
                onPressed: () => bibleController.clearSelection(),
                icon: Icon(Icons.close, color: colorController.textColor.value),
                tooltip: l10n.clear,
              ),
              Container(
                width: 1,
                height: 24,
                color: colorController.textColor.value.withValues(alpha: 0.2),
              ),
              // Highlight/Save
              IconButton(
                onPressed: () => bibleController.saveHighlight(),
                icon: const Icon(Icons.highlight_rounded, color: Colors.orange),
                tooltip: l10n.saveChanges,
              ),
            ],
          ),
        ),
      );
    });
  }
}