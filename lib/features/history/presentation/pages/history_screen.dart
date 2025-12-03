import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fihirana/features/history/presentation/controllers/history_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/features/hymn/presentation/pages/hymn_detail_screen.dart';
import 'package:fihirana/features/history/presentation/widgets/history_item_card.dart';
import 'package:fihirana/shared/widgets/common/localization_extension.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class HistoryScreen extends StatelessWidget {
  final HistoryController historyController = Get.find<HistoryController>();
  final ColorController colorController = Get.find<ColorController>();

  HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Obx(() {
      final backgroundColor = colorController.backgroundColor.value;
      final textColor = colorController.textColor.value;
      final iconColor = colorController.iconColor.value;
      final primaryColor = colorController.primaryColor.value;

      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
title: Text(
            historyController.isSelectionMode.value
                ? '${historyController.selectedItems.length} ${context.translate((l) => l.selected)}'
                : context.translate((l) => l.history),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          leading: historyController.isSelectionMode.value
              ? IconButton(
                  icon: Icon(Icons.close, color: iconColor),
                  onPressed: historyController.toggleSelectionMode,
                )
              : IconButton(
                  icon: Icon(Icons.menu_rounded, color: iconColor),
                  onPressed: () => Get.find<ShellController>().toggleDrawer(),
                ),
          actions: [
            if (historyController.isSelectionMode.value) ...[
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showDeleteSelectedDialog(context),
              ),
            ] else ...[
              if (historyController.userHistory.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: iconColor),
                  onPressed: () => _showClearHistoryDialog(context),
                ),
            ],
          ],
        ),
        body: historyController.isLoading.value
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : historyController.userHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history,
                                size: 64,
                                color: textColor.withValues(alpha: 0.3))
                            .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true))
                            .scale(
                                duration: const Duration(seconds: 2),
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1),
                                curve: Curves.easeInOut),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noHistory,
                          style: TextStyle(
                              color: textColor.withValues(alpha: 0.7),
                              fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: historyController.userHistory.length,
                     itemBuilder: (context, index) {
                       final history = historyController.userHistory[index];
                       final isSelected = historyController.selectedItems.contains(history['id']);

                       return HistoryItemCard(
                         history: history,
                         index: index,
                         isSelected: isSelected,
                         isSelectionMode: historyController.isSelectionMode.value,
                         onTap: () {
                           if (historyController.isSelectionMode.value) {
                             historyController.toggleItemSelection(history['id']);
                           } else {
                             Get.to(() => HymnDetailScreen(hymnId: history['hymnId']));
                           }
                         },
                         onLongPress: () {
                           if (!historyController.isSelectionMode.value) {
                             historyController.toggleSelectionMode();
                             historyController.toggleItemSelection(history['id']);
                           }
                         },
                         onSelectionChanged: (_) => historyController.toggleItemSelection(history['id']),
                       );
                     },
                  ),
      );
    });
  }

void _showClearHistoryDialog(BuildContext context) {
    final textColor = colorController.textColor.value;
    final backgroundColor = colorController.backgroundColor.value;

    Get.dialog(
      AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(context.translate((l) => l.clearAllHistoryQuestion),
            style: TextStyle(color: textColor)),
        content: Text(context.translate((l) => l.historyCannotBeUndone),
            style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.translate((l) => l.no), style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              historyController.clearHistory();
              Get.back();
            },
            child: Text(context.translate((l) => l.yes), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

void _showDeleteSelectedDialog(BuildContext context) {
    final textColor = colorController.textColor.value;
    final backgroundColor = colorController.backgroundColor.value;

    Get.dialog(
      AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(context.translate((l) => l.deleteSelectedHistoryQuestion),
            style: TextStyle(color: textColor)),
        content: Text(context.translate((l) => l.historyCannotBeUndone),
            style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.translate((l) => l.no), style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              historyController.deleteSelectedItems();
              Get.back();
            },
            child: Text(context.translate((l) => l.yes), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
