import 'package:flutter/material.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/app_typography.dart';
import 'package:fihirana/core/design_system/components/app_sheet.dart';
import 'package:fihirana/features/bible/domain/entities/note.dart';
import 'package:fihirana/l10n/app_localizations.dart';

/// Writes or edits the reader's own note on a hymn. It comes up as a sheet of
/// the same stock as the page underneath it.
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

  bool get _hasSavedNote =>
      widget.note != null || widget.userNoteContent != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final AppSurfaces s = AppSurfaces.of(context);
    final TextTheme type = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: s.sheet,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppScale.radiusSheet)),
        border: Border.all(color: s.ruleFirm, width: AppScale.ruleHair),
      ),
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppScale.space12),
              child: Container(
                  width: 40, height: AppScale.ruleBar, color: s.ruleFirm),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppScale.gutter, 0, AppScale.gutter, AppScale.space12),
            child: Text(
              widget.note != null ? l10n.editNote : l10n.myPersonalNote,
              style: type.headlineSmall?.copyWith(color: s.ink),
            ),
          ),
          const AppRule(),
          Padding(
            padding: const EdgeInsets.all(AppScale.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.noteInstructions,
                  style: type.bodySmall?.copyWith(color: s.muted),
                ),
                const SizedBox(height: AppScale.space16),
                TextField(
                  controller: _noteController,
                  maxLines: 6,
                  minLines: 3,
                  decoration: InputDecoration(hintText: l10n.enterYourNote),
                  style: type.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: AppScale.space24),
                Row(
                  children: [
                    if (_hasSavedNote) ...[
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () =>
                              _showDeleteConfirmation(context, l10n, colors, s),
                          icon: const Icon(Icons.delete_rounded,
                              size: AppScale.iconMd),
                          label: Text(l10n.delete,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          style: TextButton.styleFrom(
                              foregroundColor: colors.error),
                        ),
                      ),
                      const SizedBox(width: AppScale.space8),
                    ],
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.cancel,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: AppScale.space8),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () {
                          final content = _noteController.text.trim();
                          widget.onSave(content);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context,
      AppLocalizations l10n, ColorScheme colors, AppSurfaces s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteNoteConfirm),
        content: Text(l10n.deleteNoteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            child: Text(l10n.yes),
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
  }
}

/// The reader's note, kept on the page it belongs to. Collapsed it is one ruled
/// line; open it is the note itself.
class ImprovedNoteSectionWidget extends StatefulWidget {
  final Note? userNote;
  final Function(Note) onNoteEdit;
  final Function() onAddNote;
  final double fontSize;

  const ImprovedNoteSectionWidget({
    super.key,
    required this.userNote,
    required this.onNoteEdit,
    required this.onAddNote,
    required this.fontSize,
  });

  @override
  State<ImprovedNoteSectionWidget> createState() =>
      _ImprovedNoteSectionWidgetState();
}

class _ImprovedNoteSectionWidgetState extends State<ImprovedNoteSectionWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final AppSurfaces s = AppSurfaces.of(context);
    final TextTheme type = Theme.of(context).textTheme;
    final note = widget.userNote;

    return Container(
      decoration: BoxDecoration(
        color: s.sheet,
        borderRadius: BorderRadius.circular(AppScale.radiusSurface),
        border: Border.all(color: s.rule, width: AppScale.ruleHair),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppScale.space16, vertical: AppScale.space12),
                child: Row(
                  children: [
                    Icon(Icons.note_rounded,
                        color: s.ink2, size: AppScale.iconMd),
                    const SizedBox(width: AppScale.space12),
                    Expanded(
                      child: Text(
                        l10n.notes,
                        style: type.bodyMedium?.copyWith(
                            color: s.ink, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (note != null)
                      Text(_formatDate(note.createdAt, l10n),
                          style: type.bodySmall?.copyWith(color: s.muted)),
                    Icon(
                      _isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: s.muted,
                      size: AppScale.iconLg,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: AppScale.durShort,
            curve: AppScale.easeOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(AppScale.space16, 0,
                        AppScale.space16, AppScale.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppRule(),
                        const SizedBox(height: AppScale.space16),
                        if (note == null) ...[
                          Text(l10n.none,
                              style: type.titleSmall?.copyWith(color: s.ink)),
                          const SizedBox(height: AppScale.space4),
                          Text(l10n.noteInstructions,
                              style: type.bodySmall?.copyWith(color: s.muted)),
                          const SizedBox(height: AppScale.space16),
                          FilledButton.tonalIcon(
                            onPressed: widget.onAddNote,
                            icon: const Icon(Icons.add_rounded,
                                size: AppScale.iconMd),
                            label: Text(l10n.myPersonalNote),
                          ),
                        ] else ...[
                          Text(
                            note.content,
                            style: type.bodyMedium?.copyWith(
                                fontSize: widget.fontSize,
                                height: AppTypography.lyricLead,
                                color: s.ink),
                          ),
                          if (note.content.length > 140) ...[
                            const SizedBox(height: AppScale.space8),
                            Text(l10n.readMore,
                                style:
                                    type.bodySmall?.copyWith(color: s.muted)),
                          ],
                          const SizedBox(height: AppScale.space16),
                          TextButton.icon(
                            onPressed: () => widget.onNoteEdit(note),
                            icon: const Icon(Icons.edit_rounded,
                                size: AppScale.iconMd),
                            label: Text(l10n.editNote,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime, AppLocalizations l10n) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) return l10n.justNow;
        return l10n.minutesAgo(difference.inMinutes);
      }
      return l10n.hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    }
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
