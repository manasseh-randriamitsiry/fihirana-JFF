import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/design_system/app_scale.dart';

class CreatePlaylistDialog extends StatefulWidget {
  final String title;
  final String hint;
  final Function(String title, DateTime date) onCreate;

  const CreatePlaylistDialog({
    super.key,
    required this.title,
    required this.hint,
    required this.onCreate,
  });

  @override
  State<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<CreatePlaylistDialog> {
  final titleController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      backgroundColor: colorController.backgroundColor.value,
      title: Text(
        widget.title,
        style: TextStyle(color: colorController.textColor.value),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            style: TextStyle(color: colorController.textColor.value),
            decoration: InputDecoration(
              labelText: l10n.title,
              hintText: widget.hint,
              labelStyle: TextStyle(
                  color:
                      colorController.textColor.value.withValues(alpha: 0.7)),
              hintStyle: TextStyle(
                  color:
                      colorController.textColor.value.withValues(alpha: 0.5)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color:
                        colorController.textColor.value.withValues(alpha: 0.3)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: colorController.primaryColor.value),
              ),
            ),
          ),
          const SizedBox(height: AppScale.space16),
          Material(
            color: colorController.textColor.value.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppScale.radiusRow),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppScale.radiusRow),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: colorController.primaryColor.value,
                          onPrimary: Colors.white,
                          surface: colorController.backgroundColor.value,
                          onSurface: colorController.textColor.value,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(AppScale.space16),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: AppScale.iconMd,
                        color: colorController.primaryColor.value),
                    const SizedBox(width: AppScale.space12),
                    Text(
                      DateFormat('MMM d, yyyy').format(selectedDate),
                      style: TextStyle(
                        fontSize: 16,
                        color: colorController.textColor.value,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel,
              style: TextStyle(color: colorController.textColor.value)),
        ),
        FilledButton(
          onPressed: () {
            if (titleController.text.isNotEmpty) {
              widget.onCreate(titleController.text, selectedDate);
              Navigator.pop(context);
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: colorController.primaryColor.value,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.create),
        ),
      ],
    );
  }
}
