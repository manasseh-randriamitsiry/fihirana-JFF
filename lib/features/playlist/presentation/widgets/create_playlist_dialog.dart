import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/l10n/app_localizations.dart';

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
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = AppSurfaces.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: l10n.title,
              hintText: widget.hint,
            ),
          ),
          const SizedBox(height: AppScale.space16),
          Material(
            color: s.paper2,
            borderRadius: BorderRadius.circular(AppScale.radiusRow),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppScale.radiusRow),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null && mounted) {
                  setState(() => _selectedDate = date);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(AppScale.space16),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: AppScale.iconMd, color: s.accent),
                    const SizedBox(width: AppScale.space12),
                    Text(
                      DateFormat('MMM d, yyyy').format(_selectedDate),
                      style: Theme.of(context).textTheme.bodyLarge,
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
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              widget.onCreate(_titleController.text, _selectedDate);
              Navigator.pop(context);
            }
          },
          child: Text(l10n.create),
        ),
      ],
    );
  }
}
