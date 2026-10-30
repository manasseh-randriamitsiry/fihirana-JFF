import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/features/history/di/history_di.dart';
import 'package:fihirana/features/history/presentation/controllers/history_controller.dart';
import 'package:fihirana/features/history/presentation/widgets/history_item_row.dart';
import 'package:fihirana/features/hymn/presentation/pages/hymn_detail_screen.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';
import 'package:fihirana/shared/widgets/common/localization_extension.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/components/app_state_view.dart';

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
    _initializeHistoryController();
  }

  Future<void> _initializeHistoryController() async {
    try {
      historyController = Get.find<HistoryController>();
    } catch (_) {
      HistoryDI.initialize();
      historyController = HistoryDI.historyController;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_isLoading || historyController == null) {
      return AppPageScaffold(
        title: l10n.history,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          icon: const Icon(Icons.menu_rounded),
          onPressed: Get.find<ShellController>().toggleDrawer,
        ),
        body: const AppRegisterSkeleton(),
      );
    }

    return Obx(() {
      final controller = historyController!;
      final ColorScheme colors = Theme.of(context).colorScheme;
      final isSelectionMode = controller.isSelectionMode.value;
      return AppPageScaffold(
        title: isSelectionMode
            ? context.translate(
                (l) => l.selectedItems(controller.selectedItems.length))
            : l10n.history,
        leading: IconButton(
          tooltip: isSelectionMode
              ? MaterialLocalizations.of(context).closeButtonTooltip
              : MaterialLocalizations.of(context).openAppDrawerTooltip,
          icon:
              Icon(isSelectionMode ? Icons.close_rounded : Icons.menu_rounded),
          onPressed: isSelectionMode
              ? controller.toggleSelectionMode
              : Get.find<ShellController>().toggleDrawer,
        ),
        actions: [
          if (isSelectionMode)
            IconButton(
              tooltip: context.translate((l) => l.delete),
              icon: Icon(Icons.delete_outline_rounded, color: colors.error),
              onPressed: () => _showDeleteSelectedDialog(context),
            )
          else if (controller.userHistory.isNotEmpty)
            IconButton(
              tooltip: context.translate((l) => l.clearAllHistory),
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () => _showClearHistoryDialog(context),
            ),
        ],
        body: AppStateView(
          state: controller.isLoading.value
              ? AppState.loading
              : controller.userHistory.isEmpty
                  ? AppState.empty
                  : AppState.full,
          emptyTitle: l10n.noHistory,
          emptyIcon: Icons.history_rounded,
          child: ListView.separated(
            key: const PageStorageKey('history_list'),
            padding: const EdgeInsets.fromLTRB(AppScale.gutter, AppScale.space8,
                AppScale.gutter, AppScale.space24),
            itemCount: controller.userHistory.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppScale.buttonGap),
            itemBuilder: (context, index) {
              final history = controller.userHistory[index];
              final isSelected =
                  controller.selectedItems.contains(history['id']);
              return HistoryItemRow(
                key: ValueKey(history['id']),
                history: history,
                isSelected: isSelected,
                isSelectionMode: isSelectionMode,
                onTap: () {
                  if (isSelectionMode) {
                    controller.toggleItemSelection(history['id']);
                  } else {
                    Get.to(() => HymnDetailScreen(hymnId: history['hymnId']));
                  }
                },
                onLongPress: () {
                  if (!isSelectionMode) {
                    controller.toggleSelectionMode();
                    controller.toggleItemSelection(history['id']);
                  }
                },
                onSelectionChanged: (_) =>
                    controller.toggleItemSelection(history['id']),
              );
            },
          ),
        ),
      );
    });
  }

  void _showClearHistoryDialog(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Get.dialog(
      AlertDialog(
        title: Text(context.translate((l) => l.clearAllHistoryQuestion)),
        content: Text(context.translate((l) => l.historyCannotBeUndone)),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(context.translate((l) => l.no)),
          ),
          TextButton(
            onPressed: () {
              historyController!.clearHistory();
              Get.back();
            },
            child: Text(
              context.translate((l) => l.yes),
              style: TextStyle(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteSelectedDialog(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Get.dialog(
      AlertDialog(
        title: Text(context.translate((l) => l.deleteSelectedHistoryQuestion)),
        content: Text(context.translate((l) => l.historyCannotBeUndone)),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(context.translate((l) => l.no)),
          ),
          TextButton(
            onPressed: () {
              historyController!.deleteSelectedItems();
              Get.back();
            },
            child: Text(
              context.translate((l) => l.yes),
              style: TextStyle(color: colors.error),
            ),
          ),
        ],
      ),
    );
  }
}
