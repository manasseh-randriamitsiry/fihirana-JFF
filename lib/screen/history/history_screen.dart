import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controller/history_controller.dart';
import '../../controller/color_controller.dart';
import '../hymn/hymn_detail_screen.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_localizations.dart';

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
                ? '${historyController.selectedItems.length} voafidy'
                : 'Tantara',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          leading: historyController.isSelectionMode.value
              ? IconButton(
                  icon: Icon(Icons.close, color: iconColor),
                  onPressed: historyController.toggleSelectionMode,
                )
              : IconButton(
                  icon:
                      Icon(Icons.arrow_back_ios_new_rounded, color: iconColor),
                  onPressed: () => Get.back(),
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
                                size: 64, color: textColor.withValues(alpha: 0.3))
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
                              color: textColor.withValues(alpha: 0.7), fontSize: 16),
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
                      final DateTime timestamp = history['timestamp'];
                      final String formattedDate =
                          DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
                      final isSelected = historyController.selectedItems
                          .contains(history['id']);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          color: backgroundColor,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: primaryColor,
                              radius: 25,
                              child: Text(
                                '${history['number']}',
                                style: TextStyle(
                                  color: backgroundColor, // Assuming contrast
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              history['title'] ?? 'Hira ${history['number']}',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              formattedDate,
                              style:
                                  TextStyle(color: textColor.withValues(alpha: 0.6)),
                            ),
                            trailing: historyController.isSelectionMode.value
                                ? Checkbox(
                                    value: isSelected,
                                    activeColor: primaryColor,
                                    side: BorderSide(
                                        color: textColor.withValues(alpha: 0.5)),
                                    onChanged: (_) => historyController
                                        .toggleItemSelection(history['id']),
                                  )
                                : null,
                            onTap: () {
                              if (historyController.isSelectionMode.value) {
                                historyController
                                    .toggleItemSelection(history['id']);
                              } else {
                                Get.to(() => HymnDetailScreen(
                                    hymnId: history['hymnId']));
                              }
                            },
                            onLongPress: () {
                              if (!historyController.isSelectionMode.value) {
                                historyController.toggleSelectionMode();
                                historyController
                                    .toggleItemSelection(history['id']);
                              }
                            },
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(
                              duration: const Duration(milliseconds: 300),
                              delay: Duration(milliseconds: 50 * index))
                          .slideY(
                              begin: 0.1,
                              end: 0,
                              duration: const Duration(milliseconds: 300),
                              delay: Duration(milliseconds: 50 * index),
                              curve: Curves.easeOut);
                    },
                  ),
      );
    });
  }

  void _showClearHistoryDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textColor = colorController.textColor.value;
    final backgroundColor = colorController.backgroundColor.value;

    Get.dialog(
      AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(l10n.clearAllHistoryQuestion,
            style: TextStyle(color: textColor)),
        content: Text(l10n.historyCannotBeUndone,
            style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(l10n.no, style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              historyController.clearHistory();
              Get.back();
            },
            child: Text(l10n.yes, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteSelectedDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textColor = colorController.textColor.value;
    final backgroundColor = colorController.backgroundColor.value;

    Get.dialog(
      AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(l10n.deleteSelectedHistoryQuestion,
            style: TextStyle(color: textColor)),
        content: Text(l10n.historyCannotBeUndone,
            style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(l10n.no, style: TextStyle(color: textColor)),
          ),
          TextButton(
            onPressed: () {
              historyController.deleteSelectedItems();
              Get.back();
            },
            child: Text(l10n.yes, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
