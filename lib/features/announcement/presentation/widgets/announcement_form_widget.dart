import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class AnnouncementFormWidget extends StatefulWidget {
  final String title;
  final String submitButtonText;
  final String? initialTitle;
  final String? initialMessage;
  final DateTime? initialExpirationDate;
  final VoidCallback onSubmit;

  const AnnouncementFormWidget({
    super.key,
    required this.title,
    required this.submitButtonText,
    this.initialTitle,
    this.initialMessage,
    this.initialExpirationDate,
    required this.onSubmit,
  });

  @override
  State<AnnouncementFormWidget> createState() => _AnnouncementFormWidgetState();
}

class _AnnouncementFormWidgetState extends State<AnnouncementFormWidget> {
  late TextEditingController _titleController;
  late TextEditingController _messageController;
  DateTime? _selectedExpirationDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _messageController = TextEditingController(text: widget.initialMessage);
    _selectedExpirationDate = widget.initialExpirationDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectExpirationDate(StateSetter setState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpirationDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedExpirationDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.title,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: l10n.message,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectExpirationDate(setState),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.expirationDate,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedExpirationDate != null
                                  ? DateFormat('dd/MM/yyyy')
                                      .format(_selectedExpirationDate!)
                                  : widget.initialTitle != null
                                      ? l10n.noExpirationDate
                                      : l10n.noDate,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel2),
          ),
          FilledButton(
            onPressed: () {
              if (_titleController.text.trim().isEmpty ||
                  _messageController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.fillAllFields)),
                );
                return;
              }
              widget.onSubmit();
              Navigator.pop(context);
            },
            child: Text(widget.submitButtonText),
          ),
        ],
      ),
    );
  }
}
