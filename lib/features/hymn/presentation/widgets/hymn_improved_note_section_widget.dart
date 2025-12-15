import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/bible/domain/entities/note.dart';
import 'package:fihirana/features/bible/data/services/note_service.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';

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
    final l10n = AppLocalizations.of(context);
    final colorController = Get.find<ColorController>();
    final primaryColor = colorController.primaryColor.value;
    final backgroundColor = colorController.backgroundColor.value;
    final textColor = colorController.textColor.value;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: primaryColor, width: 2),
          left: BorderSide(color: primaryColor, width: 2),
          right: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Title with icon
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.note != null ? Icons.edit_note_rounded : Icons.note_add_rounded,
                    size: 24,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.note != null ? l10n.editNote : l10n.myPersonalNote,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Divider(
            color: primaryColor.withValues(alpha: 0.2),
            thickness: 1,
            height: 1,
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.noteInstructions,
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Text field
                TextField(
                  controller: _noteController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: l10n.enterYourNote,
                    hintStyle: TextStyle(
                      color: textColor.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: primaryColor.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: primaryColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Action buttons
                Row(
                  children: [
                    // Delete button
                    if (widget.note != null || widget.userNoteContent != null)
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.delete_outline_rounded,
                          label: l10n.delete,
                          color: Colors.red,
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          onPressed: () => _showDeleteConfirmation(context, l10n, colorController),
                        ),
                      ),
                    if (widget.note != null || widget.userNoteContent != null)
                      const SizedBox(width: 12),
                    
                    // Cancel button
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.close_rounded,
                        label: l10n.cancel,
                        color: textColor.withValues(alpha: 0.7),
                        backgroundColor: textColor.withValues(alpha: 0.08),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Save button
                    Expanded(
                      flex: 2,
                      child: _buildActionButton(
                        icon: Icons.check_rounded,
                        label: l10n.save,
                        color: backgroundColor,
                        backgroundColor: primaryColor,
                        onPressed: () {
                          final content = _noteController.text.trim();
                          widget.onSave(content);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    AppLocalizations l10n,
    ColorController colorController,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: colorController.backgroundColor.value,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.deleteNoteConfirm,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorController.textColor.value,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.deleteNoteMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: colorController.textColor.value.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: colorController.textColor.value.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: Text(
                        l10n.no,
                        style: TextStyle(
                          color: colorController.textColor.value,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.yes,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

class ImprovedNoteSectionWidget extends StatefulWidget {
  final bool isUserAuthenticated;
  final List<Note> publicNotes;
  final Note? userNote;
  final Function(Note) onNoteEdit;
  final Function() onAddNote;
  final double fontSize;

  const ImprovedNoteSectionWidget({
    super.key,
    required this.isUserAuthenticated,
    required this.publicNotes,
    this.userNote,
    required this.onNoteEdit,
    required this.onAddNote,
    required this.fontSize,
  });

  @override
  State<ImprovedNoteSectionWidget> createState() =>
      _ImprovedNoteSectionWidgetState();
}

class _ImprovedNoteSectionWidgetState extends State<ImprovedNoteSectionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isExpanded = false;
  bool _showCommunityNotes = false;
  final NoteService _noteService = NoteService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorController = Get.find<ColorController>();

    if (!widget.isUserAuthenticated && widget.publicNotes.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalNotes =
        (widget.userNote != null ? 1 : 0) + widget.publicNotes.length;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.all(AppDimensions.md),
              decoration: BoxDecoration(
                color: colorController.primaryColor.value.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                 border: Border.all(
                   color: _isExpanded
                       ? colorController.primaryColor.value
                           .withValues(alpha: 0.15)
                       : Colors.transparent,
                   width: 1.5,
                 ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced header section
                  _buildHeader(colorController, l10n, totalNotes),

                  // Notes content with animation
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: _isExpanded
                        ? _buildNotesContent(colorController, l10n)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      ColorController colorController, AppLocalizations l10n, int totalNotes) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: const BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              // Animated icon
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.note_alt_outlined,
                  color: colorController.primaryColor.value.withValues(alpha: 0.5),
                  size: widget.fontSize * 1.2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.notes,
                      style: TextStyle(
                        fontSize: widget.fontSize * 1.1,
                        fontWeight: FontWeight.bold,
                        color: colorController.textColor.value,
                      ),
                    ),
                    if (totalNotes > 0)
                      Text(
                        '$totalNotes ${totalNotes == 1 ? 'note' : 'notes'}',
                        style: TextStyle(
                          fontSize: widget.fontSize * 0.8,
                          color: colorController.textColor.value
                              .withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
              // Add note button with animation
              if (widget.isUserAuthenticated)
                _buildAddNoteButton(colorController, l10n),
              // Expand/collapse icon
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: colorController.iconColor.value,
                  size: widget.fontSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddNoteButton(
      ColorController colorController, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: colorController.primaryColor.value,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // Add haptic feedback
              // HapticFeedback.lightImpact();
              widget.onAddNote();
            },
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.sm),
              child: Icon(
                widget.userNote != null ? Icons.edit : Icons.add,
                color: colorController.backgroundColor.value,
                size: widget.fontSize * 0.9,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesContent(
      ColorController colorController, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User note
          if (widget.isUserAuthenticated && widget.userNote != null) ...[
            _buildUserNote(context, widget.userNote!, colorController, l10n),
            if (widget.publicNotes.isNotEmpty) const SizedBox(height: 16),
          ],

          // Public notes section with toggle
          if (widget.publicNotes.isNotEmpty) ...[
            _buildCommunityNotesHeader(colorController, l10n),
            const SizedBox(height: 12),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              child: _showCommunityNotes
                  ? Column(
                      children: widget.publicNotes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final note = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: index < widget.publicNotes.length - 1
                                  ? 12.0
                                  : 0),
                          child: _buildPublicNote(
                              context, note, colorController, l10n),
                        );
                      }).toList(),
                    )
                  : const SizedBox.shrink(),
            ),
          ],

          // Empty state for authenticated users
          if (widget.isUserAuthenticated &&
              widget.userNote == null &&
              widget.publicNotes.isEmpty)
            _buildEmptyState(context, colorController, l10n),
        ],
      ),
    );
  }

  Widget _buildCommunityNotesHeader(
      ColorController colorController, AppLocalizations l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _showCommunityNotes = !_showCommunityNotes),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.xs),
          child: Row(
            children: [
              Icon(
                Icons.public,
                color: colorController.textColor.value.withValues(alpha: 0.7),
                size: widget.fontSize * 0.9,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Community Notes (${widget.publicNotes.length})',
                  style: TextStyle(
                    fontSize: widget.fontSize * 0.9,
                    fontWeight: FontWeight.w600,
                    color:
                        colorController.textColor.value.withValues(alpha: 0.7),
                  ),
                ),
              ),
              AnimatedRotation(
                turns: _showCommunityNotes ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: colorController.textColor.value.withValues(alpha: 0.5),
                  size: widget.fontSize * 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserNote(
    BuildContext context,
    Note note,
    ColorController colorController,
    AppLocalizations l10n,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onNoteEdit(note),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: colorController.primaryColor.value.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorController.primaryColor.value.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorController.primaryColor.value,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person,
                      color: colorController.backgroundColor.value,
                      size: widget.fontSize * 0.8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.myPersonalNote,
                          style: TextStyle(
                            fontSize: widget.fontSize * 0.95,
                            fontWeight: FontWeight.bold,
                            color: colorController.primaryColor.value,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: widget.fontSize * 0.6,
                              color: colorController.textColor.value
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(note.createdAt),
                              style: TextStyle(
                                fontSize: widget.fontSize * 0.75,
                                color: colorController.textColor.value
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: colorController.backgroundColor.value,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorController.primaryColor.value
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.edit,
                        size: widget.fontSize * 0.8,
                        color: colorController.primaryColor.value,
                      ),
                      onPressed: () => widget.onNoteEdit(note),
                      tooltip: l10n.editNote,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                note.content,
                style: TextStyle(
                  fontSize: widget.fontSize * 0.9,
                  color: colorController.textColor.value,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (note.content.length > 100)
                Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.xs),
                  child: Text(
                    'Tap to see more...',
                    style: TextStyle(
                      fontSize: widget.fontSize * 0.75,
                      color: colorController.primaryColor.value,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to check if current user can edit a note
  Future<bool> _canEditNote(Note note) async {
    return await _noteService.canEditNote(note);
  }

  Widget _buildPublicNote(
    BuildContext context,
    Note note,
    ColorController colorController,
    AppLocalizations l10n,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final canEdit = await _canEditNote(note);
          if (canEdit) {
            widget.onNoteEdit(note);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: colorController.backgroundColor.value,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorController.textColor.value.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: widget.fontSize * 0.4,
                    backgroundColor: colorController.primaryColor.value
                        .withValues(alpha: 0.2),
                    child: Text(
                      note.userName.isNotEmpty
                          ? note.userName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: widget.fontSize * 0.5,
                        fontWeight: FontWeight.bold,
                        color: colorController.primaryColor.value,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.userName,
                          style: TextStyle(
                            fontSize: widget.fontSize * 0.9,
                            fontWeight: FontWeight.w600,
                            color: colorController.textColor.value,
                          ),
                        ),
                        if (note.userEmail.isNotEmpty &&
                            note.userEmail != note.userName)
                          Text(
                            note.userEmail,
                            style: TextStyle(
                              fontSize: widget.fontSize * 0.75,
                              color: colorController.textColor.value
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: widget.fontSize * 0.6,
                              color: colorController.textColor.value
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(note.createdAt),
                              style: TextStyle(
                                fontSize: widget.fontSize * 0.75,
                                color: colorController.textColor.value
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder<bool>(
                    future: _canEditNote(note),
                    builder: (context, snapshot) {
                      final canEdit = snapshot.data ?? false;
                      if (!canEdit) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        decoration: BoxDecoration(
                          color: colorController.textColor.value
                              .withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorController.textColor.value
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: widget.fontSize * 0.8,
                            color: colorController.primaryColor.value,
                          ),
                          onPressed: () => widget.onNoteEdit(note),
                          tooltip: l10n.editNote,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                note.content,
                style: TextStyle(
                  fontSize: widget.fontSize * 0.9,
                  color: colorController.textColor.value,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (note.content.length > 80)
                Padding(
                  padding: const EdgeInsets.only(top: AppDimensions.xs),
                  child: Text(
                    'Tap to read more...',
                    style: TextStyle(
                      fontSize: widget.fontSize * 0.75,
                      color: colorController.primaryColor.value,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorController colorController,
    AppLocalizations l10n,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onAddNote,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppDimensions.lg),
          decoration: BoxDecoration(
            color: colorController.backgroundColor.value,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorController.primaryColor.value.withValues(alpha: 0.2),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      colorController.primaryColor.value.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.note_add_outlined,
                  size: widget.fontSize * 2,
                  color: colorController.primaryColor.value,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No notes yet',
                style: TextStyle(
                  fontSize: widget.fontSize,
                  color: colorController.textColor.value.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Add your first note to get started',
                style: TextStyle(
                  fontSize: widget.fontSize * 0.85,
                  color: colorController.textColor.value.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorController.primaryColor.value,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      color: colorController.backgroundColor.value,
                      size: widget.fontSize * 0.8,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add Note',
                      style: TextStyle(
                        color: colorController.backgroundColor.value,
                        fontSize: widget.fontSize * 0.85,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
