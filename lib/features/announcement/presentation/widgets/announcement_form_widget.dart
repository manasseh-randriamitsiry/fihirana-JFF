import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fihirana/app/theme/color_controller.dart';
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
    final colorController = Get.find<ColorController>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedExpirationDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: colorController.primaryColor.value,
              brightness: Theme.of(context).brightness,
            ).copyWith(
              surface: colorController.backgroundColor.value,
              onSurface: colorController.textColor.value,
              primary: colorController.primaryColor.value,
              onPrimary: colorController.primaryColor.value,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: colorController.backgroundColor.value,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedExpirationDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final l10n = AppLocalizations.of(context);

    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          widget.title,
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.title,
                  labelStyle: TextStyle(color: colorController.textColor.value),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: colorController.textColor.value
                            .withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: colorController.primaryColor.value, width: 2),
                  ),
                ),
                style: TextStyle(color: colorController.textColor.value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: l10n.message,
                  labelStyle: TextStyle(color: colorController.textColor.value),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: colorController.textColor.value
                            .withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: colorController.primaryColor.value, width: 2),
                  ),
                ),
                style: TextStyle(color: colorController.textColor.value),
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
                        color: colorController.textColor.value
                            .withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: colorController.iconColor.value, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.expirationDate,
                              style: TextStyle(
                                color: colorController.textColor.value
                                    .withValues(alpha: 0.7),
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
                              style: TextStyle(
                                color: colorController.textColor.value,
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
            child: Text(l10n.cancel2,
                style: TextStyle(color: colorController.textColor.value)),
          ),
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: colorController.primaryColor.value,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(widget.submitButtonText),
          ),
        ],
      ),
    );
  }
}
