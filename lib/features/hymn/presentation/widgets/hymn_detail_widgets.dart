import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/bible/domain/entities/note.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'hymn_improved_note_section_widget.dart';
import 'hymn_hint_section.dart';
import 'hymn_verses_section.dart';
import 'hymn_separator.dart';

class HymnPageWidget extends StatelessWidget {
  final Hymn hymn;
  final double fontSize;
  final double countFontSize;
  final bool showHint;
  final bool isUserAuthenticated;
  final List<Note> publicNotes;
  final Note? userNote;
  final Function(Note) onNoteEdit;

  const HymnPageWidget({
    super.key,
    required this.hymn,
    required this.fontSize,
    required this.countFontSize,
    required this.showHint,
    required this.isUserAuthenticated,
    required this.publicNotes,
    this.userNote,
    required this.onNoteEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return Container(
      key: ValueKey(hymn.id),
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      color: colorController.backgroundColor.value,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hymn hint section
            HymnHintSection(
              hymn: hymn,
              fontSize: fontSize,
              showHint: showHint,
              isUserAuthenticated: isUserAuthenticated,
            ),

            // Verses section
            HymnVersesSection(
              hymn: hymn,
              fontSize: fontSize,
              countFontSize: countFontSize,
            ),

            // Visual separator
            const HymnSeparator(),

            // Improved note section at the end
            ImprovedNoteSectionWidget(
              isUserAuthenticated: isUserAuthenticated,
              publicNotes: publicNotes,
              userNote: userNote,
              onNoteEdit: onNoteEdit,
              onAddNote: () => onNoteEdit(userNote ?? Note(
                id: '',
                hymnId: hymn.id,
                userId: '',
                userEmail: '',
                content: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                userName: '',
              )),
              fontSize: fontSize,
            ),

            SizedBox(
              height: MediaQuery.of(context).size.height / 3,
            ),
          ],
        ),
      ),
    );
  }
}

class HymnVerseDisplayWidget extends StatelessWidget {
  final int verseNumber;
  final String verseText;
  final double fontSize;
  final double countFontSize;

  const HymnVerseDisplayWidget({
    super.key,
    required this.verseNumber,
    required this.verseText,
    required this.fontSize,
    required this.countFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  '$verseNumber',
                  style: TextStyle(
                    fontSize: countFontSize,
                    fontWeight: FontWeight.bold,
                    color: colorController.primaryColor.value,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: Text(
              '$verseNumber. $verseText',
              style: TextStyle(
                fontSize: fontSize,
                color: colorController.textColor.value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HymnBridgeWidget extends StatelessWidget {
  final String bridge;
  final bool isExpanded;
  final double fontSize;
  final VoidCallback onToggle;

  const HymnBridgeWidget({
    super.key,
    required this.bridge,
    required this.isExpanded,
    required this.fontSize,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorController = Get.find<ColorController>();
    
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.everyVerseChorus,
                  style: TextStyle(
                    fontSize: fontSize + 2,
                    fontWeight: FontWeight.bold,
                    color: colorController.textColor.value,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: colorController.iconColor.value,
                ),
              ],
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  bridge,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: colorController.textColor.value,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}