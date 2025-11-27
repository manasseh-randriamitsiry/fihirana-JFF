import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/color_controller.dart';
import '../../l10n/app_localizations.dart';

class FormTextFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final IconData? icon;
  final void Function(String)? onChanged;

  const FormTextFieldWidget({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    return Container(
      decoration: BoxDecoration(
        color: colorController.backgroundColor.value,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorController.textColor.value.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(color: colorController.textColor.value),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              color: colorController.textColor.value.withValues(alpha: 0.7)),
          prefixIcon: icon != null
              ? Icon(icon, color: colorController.iconColor.value, size: 20)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: colorController.primaryColor.value,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }
}

class VerseFieldWidget extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final VoidCallback onDelete;
  final VoidCallback? onChanged;

  const VerseFieldWidget({
    super.key,
    required this.index,
    required this.controller,
    required this.onDelete,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorController = Get.find<ColorController>();
    return Card(
      key: ValueKey(index),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorController.textColor.value.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      color: colorController.backgroundColor.value,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                maxLines: null,
                style: TextStyle(color: colorController.textColor.value),
                decoration: InputDecoration(
                  labelText: l10n.verseWithNumber(index + 1),
                  labelStyle: TextStyle(
                    color:
                        colorController.textColor.value.withValues(alpha: 0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onChanged: (value) {
                  onChanged?.call();
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.enterVerse;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: Colors.red, size: 22),
              onPressed: onDelete,
              tooltip: l10n.deleteVerse,
            ),
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle,
                color: colorController.iconColor.value.withValues(alpha: 0.5),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Debouncer {
  final int milliseconds;
  Timer? _timer;
  bool _isDisposed = false;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    if (_isDisposed) return;

    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _timer = null;
  }
}