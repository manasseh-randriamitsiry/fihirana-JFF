import 'dart:async';

import 'package:flutter/material.dart';

import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

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
    final colors = Theme.of(context).colorScheme;
    return AppGroupedSurface(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: icon == null ? null : Icon(icon, size: 20),
            border: InputBorder.none,
            errorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.error),
            ),
            focusedErrorBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colors.error, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
          ),
        ),
      ],
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
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return AppGroupedSurface(
      key: ValueKey(index),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller,
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: l10n.verseWithNumber(index + 1),
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
                icon: Icon(Icons.delete_outline, color: colors.error, size: 22),
                onPressed: onDelete,
                tooltip: l10n.deleteVerse,
              ),
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_handle,
                  color: colors.onSurfaceVariant,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ],
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
