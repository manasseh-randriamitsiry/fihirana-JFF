import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/history/presentation/controllers/history_controller.dart';
import 'package:fihirana/features/history/di/history_di.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/features/hymn/presentation/pages/hymn_detail_screen.dart';
import 'package:fihirana/features/history/presentation/widgets/history_item_card.dart';
import 'package:fihirana/shared/widgets/common/localization_extension.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryController? historyController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load the history controller if not already loaded
    _initializeHistoryController();
  }

  Future<void> _initializeHistoryController() async {
    try {
      historyController = Get.find<HistoryController>();
    } catch (e) {
      // Controller not found, initialize it
      HistoryDI.initialize();
      historyController = HistoryDI.historyController;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    if (_isLoading || historyController == null) {
      return Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          title: Text(
            l10n.history,
            style: TextStyle(color: colors.onSurface),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Obx(() {
      // Safety check - should not happen since we check above
      if (historyController == null) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final backgroundColor = colors.surface;
      final textColor = colors.onSurface;
      final iconColor = colors.onSurface;

      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            historyController!.isSelectionMode.value
                ? '${historyController!.selectedItems.length} ${context.translate((l) => l.selected)}'
                : context.translate((l) => l.history),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          leading: historyController!.isSelectionMode.value
              ? IconButton(
                  icon: Icon(Icons.close, color: iconColor),
                  onPressed: historyController!.toggleSelectionMode,
                )
              : IconButton(
                  icon: Icon(Icons.menu_rounded, color: iconColor),
                  onPressed: () => Get.find<ShellController>().toggleDrawer(),
                ),
          actions: [
            if (historyController!.isSelectionMode.value) ...[
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showDeleteSelectedDialog(context),
              ),
            ] else ...[
              if (historyController!.userHistory.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: iconColor),
                  onPressed: () => _showClearHistoryDialog(context),
                ),
            ],
          ],
        ),
        body: historyController!.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : historyController!.userHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 64,
                          color: textColor.withValues(alpha: 0.3),
                        ),
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
                    key: const PageStorageKey('history_list'),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: historyController!.userHistory.length,
                    itemBuilder: (context, index) {
                      final history = historyController!.userHistory[index];
                      final isSelected = historyController!.selectedItems
                          .contains(history['id']);

                      return HistoryItemCard(
                        key: ValueKey(history['id']),
                        history: history,
                        index: index,
                        isSelected: isSelected,
                        isSelectionMode:
                            historyController!.isSelectionMode.value,
                        onTap: () {
                          if (historyController!.isSelectionMode.value) {
                            historyController!
                                .toggleItemSelection(history['id']);
                          } else {
                            Get.to(() =>
                                HymnDetailScreen(hymnId: history['hymnId']));
                          }
                        },
                        onLongPress: () {
                          if (!historyController!.isSelectionMode.value) {
                            historyController!.toggleSelectionMode();
                            historyController!
                                .toggleItemSelection(history['id']);
                          }
                        },
                        onSelectionChanged: (_) => historyController!
                            .toggleItemSelection(history['id']),
                      );
                    },
                  ),
      );
    });
  }

  void _showClearHistoryDialog(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Get.dialog(
      AlertDialog(
        backgroundColor: colors.surfaceContainerHigh,
        title: Text(context.translate((l) => l.clearAllHistoryQuestion),
            style: TextStyle(color: colors.onSurface)),
        content: Text(context.translate((l) => l.historyCannotBeUndone),
            style: TextStyle(color: colors.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.translate((l) => l.no),
                style: TextStyle(color: colors.primary)),
          ),
          TextButton(
            onPressed: () {
              historyController!.clearHistory();
              Get.back();
            },
            child: Text(context.translate((l) => l.yes),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteSelectedDialog(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Get.dialog(
      AlertDialog(
        backgroundColor: colors.surfaceContainerHigh,
        title: Text(context.translate((l) => l.deleteSelectedHistoryQuestion),
            style: TextStyle(color: colors.onSurface)),
        content: Text(context.translate((l) => l.historyCannotBeUndone),
            style: TextStyle(color: colors.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(context.translate((l) => l.no),
                style: TextStyle(color: colors.primary)),
          ),
          TextButton(
            onPressed: () {
              historyController!.deleteSelectedItems();
              Get.back();
            },
            child: Text(context.translate((l) => l.yes),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
