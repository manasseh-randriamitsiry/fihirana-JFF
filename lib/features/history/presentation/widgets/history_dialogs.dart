import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/history/di/history_di.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class ClearHistoryDialogWidget extends StatelessWidget {
  const ClearHistoryDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorController = Get.find<ColorController>();
    final historyController = HistoryDI.historyController;
    final textColor = colorController.textColor.value;
    final backgroundColor = colorController.backgroundColor.value;

    return AlertDialog(
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
    );
  }
}

class DeleteSelectedHistoryDialogWidget extends StatelessWidget {
  const DeleteSelectedHistoryDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorController = Get.find<ColorController>();
    final historyController = HistoryDI.historyController;
    final textColor = colorController.textColor.value;
    final backgroundColor = colorController.backgroundColor.value;

    return AlertDialog(
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
    );
  }
}