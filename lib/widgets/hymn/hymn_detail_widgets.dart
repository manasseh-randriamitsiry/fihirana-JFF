import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../models/hymn.dart';
import '../../models/note.dart';
import '../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
            if (showHint &&
                (hymn.hymnHint?.trim().toLowerCase().isNotEmpty ?? false)) ...[
              if (isUserAuthenticated)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorController.primaryColor.value.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.createdBy}: ${hymn.createdBy}',
                        style: TextStyle(
                          fontSize: fontSize * 0.8,
                          color: colorController.textColor.value,
                        ),
                      ),
                      if (hymn.createdByEmail != null)
                        Text(
                          l10n.emailLabel(hymn.createdByEmail!),
                          style: TextStyle(
                            fontSize: fontSize * 0.8,
                            color: colorController.textColor.value,
                          ),
                        ),
                      Text(
                        '${l10n.date}: ${DateTime.fromMillisecondsSinceEpoch(hymn.createdAt.millisecondsSinceEpoch).toString().substring(0, 19)}',
                        style: TextStyle(
                          fontSize: fontSize * 0.8,
                          color: colorController.textColor.value,
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                  hymn.hymnHint ?? '',
                  style: TextStyle(
                    fontSize: 2 * fontSize / 3,
                    color: colorController.textColor.value,
                  ),
                ),
              ),
            ],
            if (isUserAuthenticated && publicNotes.isNotEmpty) ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: publicNotes.length,
                itemBuilder: (context, index) {
                  final note = publicNotes[index];
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorController.backgroundColor.value.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                note.content,
                                style: TextStyle(
                                  fontSize: fontSize * 0.9,
                                  color: colorController.textColor.value,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                size: fontSize,
                                color: colorController.iconColor.value,
                              ),
                              onPressed: () => onNoteEdit(note),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  );
                },
              ),
            ],
            if (isUserAuthenticated && userNote != null) ...[
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorController.primaryColor.value.withValues(alpha: 0.1),
                  border: Border.all(
                    color: colorController.primaryColor.value.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: fontSize * 0.8,
                          color: colorController.primaryColor.value,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.myPersonalNote,
                          style: TextStyle(
                            fontSize: fontSize * 0.9,
                            fontWeight: FontWeight.bold,
                            color: colorController.primaryColor.value,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: fontSize,
                            color: colorController.iconColor.value,
                          ),
                          onPressed: () => onNoteEdit(userNote!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      userNote!.content,
                      style: TextStyle(
                        fontSize: fontSize * 0.9,
                        color: colorController.textColor.value,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            for (int i = 0; i < hymn.verses.length; i++) ...[
              Padding(
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
                            '${i + 1}',
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
                        '${i + 1}. ${hymn.verses[i]}',
                        style: TextStyle(
                          fontSize: fontSize,
                          color: colorController.textColor.value,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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