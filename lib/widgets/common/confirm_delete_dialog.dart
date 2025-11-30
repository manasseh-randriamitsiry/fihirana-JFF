import 'package:flutter/material.dart';
import '../../controller/color_controller.dart';
import 'mlkit_localization_provider.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final ColorController colorController;
  final String title;
  final String content;
  final VoidCallback onConfirm;
  final String? confirmText;
  final String? cancelText;

  const ConfirmDeleteDialog({
    super.key,
    required this.colorController,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.confirmText,
    this.cancelText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: colorController.backgroundColor.value,
      title: Text(
        title,
        style: TextStyle(color: colorController.textColor.value),
      ),
      content: Text(
        content,
        style: TextStyle(color: colorController.textColor.value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            cancelText ?? context.translateWithMLKit((l) => l.cancel),
            style: TextStyle(color: colorController.textColor.value),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          child: Text(
            confirmText ?? context.translateWithMLKit((l) => l.delete),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required ColorController colorController,
    required String title,
    required String content,
    required VoidCallback onConfirm,
    String? confirmText,
    String? cancelText,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ConfirmDeleteDialog(
        colorController: colorController,
        title: title,
        content: content,
        onConfirm: onConfirm,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }
}