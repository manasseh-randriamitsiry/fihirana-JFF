import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../models/note.dart';
import '../../l10n/app_localizations.dart';

class NoteEditorWidget extends StatefulWidget {
  final Note? note;
  final String? userNoteContent;
  final Function(String) onSave;
  final Function()? onDelete;

  const NoteEditorWidget({
    super.key,
    this.note,
    this.userNoteContent,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<NoteEditorWidget> createState() => _NoteEditorWidgetState();
}

class _NoteEditorWidgetState extends State<NoteEditorWidget> {
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(
      text: widget.note?.content ?? widget.userNoteContent ?? '',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorController = Get.find<ColorController>();
    
    return Container(
      color: colorController.backgroundColor.value,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.note != null ? l10n.editNote : l10n.myPersonalNote,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorController.textColor.value,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: colorController.iconColor.value,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noteInstructions,
            style: TextStyle(
              fontSize: 14,
              color: colorController.textColor.value.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: l10n.enterYourNote,
              hintStyle: TextStyle(
                color: colorController.textColor.value.withValues(alpha: 0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: colorController.textColor.value.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: colorController.textColor.value.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: colorController.primaryColor.value,
                ),
              ),
            ),
            style: TextStyle(
              color: colorController.textColor.value,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.note != null || widget.userNoteContent != null)
                TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: colorController.backgroundColor.value,
                        title: Text(
                          l10n.deleteNoteConfirm,
                          style: TextStyle(color: colorController.textColor.value),
                        ),
                        content: Text(
                          l10n.deleteNoteMessage,
                          style: TextStyle(color: colorController.textColor.value),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              l10n.no,
                              style: TextStyle(color: colorController.textColor.value),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              l10n.yes,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && widget.onDelete != null) {
                      widget.onDelete!();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: Text(
                    l10n.delete,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(color: colorController.textColor.value),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final content = _noteController.text.trim();
                  widget.onSave(content);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorController.primaryColor.value,
                  foregroundColor: colorController.backgroundColor.value,
                ),
                child: Text(l10n.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HymnTitleWidget extends StatelessWidget {
  final String title;
  final String hymnNumber;
  final double fontSize;
  final String hymnId;

  const HymnTitleWidget({
    super.key,
    required this.title,
    required this.hymnNumber,
    required this.fontSize,
    required this.hymnId,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    
    return Hero(
      tag: 'hymn_title_$hymnId',
      child: Material(
        color: Colors.transparent,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize * 1.2,
            fontWeight: FontWeight.bold,
            color: colorController.textColor.value,
          ),
        ),
      ),
    );
  }
}

class HymnNumberWidget extends StatelessWidget {
  final String hymnNumber;
  final double fontSize;
  final String hymnId;
  final VoidCallback? onTap;

  const HymnNumberWidget({
    super.key,
    required this.hymnNumber,
    required this.fontSize,
    required this.hymnId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'hymn_number_$hymnId',
        child: Material(
          color: Colors.transparent,
          child: Text(
            hymnNumber,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              color: colorController.iconColor.value,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
          ),
        ),
      ),
    );
  }
}