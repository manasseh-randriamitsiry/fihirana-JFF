import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class BibleVerseSelectionSheet extends StatefulWidget {
  final String bookName;
  final int chapter;
  final int totalVerses;
  final Function(int startVerse, int endVerse) onReadVerses;

  const BibleVerseSelectionSheet({
    super.key,
    required this.bookName,
    required this.chapter,
    required this.totalVerses,
    required this.onReadVerses,
  });

  @override
  State<BibleVerseSelectionSheet> createState() =>
      _BibleVerseSelectionSheetState();
}

class _BibleVerseSelectionSheetState extends State<BibleVerseSelectionSheet> {
  int? _startVerse;
  int? _endVerse;

  @override
  void initState() {
    super.initState();
    // Do not preselect any verse by default when opening the sheet
    _startVerse = null;
    _endVerse = null;
  }

  void _onVerseTap(int verseNumber) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_startVerse == null || _endVerse == null) {
        // Nothing selected -> select single verse
        _startVerse = verseNumber;
        _endVerse = verseNumber;
      } else if (_startVerse == _endVerse) {
        // Single verse selected
        if (verseNumber == _startVerse) {
          // Tap same verse -> deselect all
          _startVerse = null;
          _endVerse = null;
        } else {
          // Tap another verse -> form range
          final lower = min(_startVerse!, verseNumber);
          final upper = max(_startVerse!, verseNumber);
          _startVerse = lower;
          _endVerse = upper;
        }
      } else {
        // Multi-verse range selected
        final minV = _startVerse!;
        final maxV = _endVerse!;

        if (verseNumber == minV - 1) {
          // Tap top neighbor -> expand top
          _startVerse = verseNumber;
        } else if (verseNumber == maxV + 1) {
          // Tap bottom neighbor -> expand bottom
          _endVerse = verseNumber;
        } else if (verseNumber == minV) {
          // Tap top boundary -> shrink top
          _startVerse = minV + 1;
        } else if (verseNumber == maxV) {
          // Tap bottom boundary -> shrink bottom
          _endVerse = maxV - 1;
        } else {
          // Tap inside range or far away -> deselect previous, select ONLY this 1 verse
          _startVerse = verseNumber;
          _endVerse = verseNumber;
        }
      }
    });
  }

  void _selectEntireChapter() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
    widget.onReadVerses(1, widget.totalVerses);
  }

  void _confirmSelection() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop();
    final start = _startVerse ?? 1;
    final end = _endVerse ?? widget.totalVerses;
    widget.onReadVerses(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorController = Get.find<ColorController>();
    final primaryColor = colorController.primaryColor.value;
    final backgroundColor = colorController.backgroundColor.value;
    final textColor = colorController.textColor.value;

    // Use two distinct colors for start and end verses
    final startColor = primaryColor;
    final isPrimaryWarm = HSLColor.fromColor(primaryColor).hue > 15 &&
        HSLColor.fromColor(primaryColor).hue < 50;
    final endColor = isPrimaryWarm
        ? const Color(0xFF0284C7) // Sky Blue if primary is warm
        : const Color(0xFFEA580C); // Deep Orange if primary is cool

    final isSingleVerse =
        _startVerse != null && _endVerse != null && _startVerse == _endVerse;

    final rangeText = _startVerse == null
        ? '${widget.bookName} ${widget.chapter}'
        : isSingleVerse
            ? '${widget.bookName} ${widget.chapter}:$_startVerse'
            : '${widget.bookName} ${widget.chapter}:$_startVerse-$_endVerse';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.bookName} ${widget.chapter}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      l10n.versesCount(widget.totalVerses),
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close_rounded,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Button: Read Full Chapter
          OutlinedButton.icon(
            onPressed: _selectEntireChapter,
            icon: Icon(Icons.auto_stories_rounded, color: primaryColor),
            label: Text(
              l10n.readEntireChapter(widget.chapter),
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Divider with label
          Row(
            children: [
              Expanded(
                  child: Divider(color: textColor.withValues(alpha: 0.15))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  l10n.orChooseVerseRange,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              Expanded(
                  child: Divider(color: textColor.withValues(alpha: 0.15))),
            ],
          ),

          const SizedBox(height: 12),

          // Range adjustment counters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Start Verse Selector (using startColor accent)
              _buildVerseStepper(
                label: l10n.fromVerse,
                value: _startVerse,
                onDecrement: () {
                  setState(() {
                    final current = _startVerse ?? 1;
                    if (current > 1) {
                      _startVerse = current - 1;
                      _endVerse ??= widget.totalVerses;
                      if (_endVerse! < _startVerse!) _endVerse = _startVerse;
                    }
                  });
                },
                onIncrement: () {
                  setState(() {
                    final current = _startVerse ?? 1;
                    if (current < widget.totalVerses) {
                      _startVerse = current + 1;
                      _endVerse ??= widget.totalVerses;
                      if (_endVerse! < _startVerse!) _endVerse = _startVerse;
                    }
                  });
                },
                accentColor: startColor,
                textColor: textColor,
              ),

              Icon(
                Icons.arrow_forward_rounded,
                color: textColor.withValues(alpha: 0.3),
                size: 20,
              ),

              // End Verse Selector (using distinct endColor accent)
              _buildVerseStepper(
                label: l10n.toVerse,
                value: _endVerse,
                onDecrement: () {
                  setState(() {
                    _startVerse ??= 1;
                    final current = _endVerse ?? widget.totalVerses;
                    if (current > _startVerse!) {
                      _endVerse = current - 1;
                    }
                  });
                },
                onIncrement: () {
                  setState(() {
                    _startVerse ??= 1;
                    final current = _endVerse ?? widget.totalVerses;
                    if (current < widget.totalVerses) {
                      _endVerse = current + 1;
                    }
                  });
                },
                accentColor: endColor,
                textColor: textColor,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Grid of verse numbers for quick tap selection
          Expanded(
            child: widget.totalVerses == 0
                ? Center(
                    child: Text(
                      l10n.noVersesFound,
                      style: TextStyle(color: textColor),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: widget.totalVerses,
                    itemBuilder: (context, index) {
                      final verse = index + 1;
                      final isStart =
                          _startVerse != null && verse == _startVerse;
                      final isEnd = _endVerse != null &&
                          verse == _endVerse &&
                          _startVerse != _endVerse;
                      final inRange = _startVerse != null &&
                          _endVerse != null &&
                          verse > _startVerse! &&
                          verse < _endVerse!;

                      Color itemBg;
                      Color itemFg;
                      Border? border;

                      if (isStart) {
                        itemBg = startColor;
                        itemFg = Colors.white;
                      } else if (isEnd) {
                        itemBg = endColor;
                        itemFg = Colors.white;
                      } else if (inRange) {
                        itemBg = Color.lerp(startColor, endColor, 0.5)!
                            .withValues(alpha: 0.25);
                        itemFg = primaryColor;
                        border = Border.all(
                          color: Color.lerp(startColor, endColor, 0.5)!
                              .withValues(alpha: 0.35),
                        );
                      } else {
                        itemBg = primaryColor.withValues(alpha: 0.08);
                        itemFg = textColor;
                        border = Border.all(
                          color: primaryColor.withValues(alpha: 0.15),
                        );
                      }

                      return InkWell(
                        onTap: () => _onVerseTap(verse),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: itemBg,
                            borderRadius: BorderRadius.circular(10),
                            border: border,
                          ),
                          child: Center(
                            child: Text(
                              '$verse',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: (isStart || isEnd)
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: itemFg,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),

          // Bottom CTA Button
          ElevatedButton.icon(
            onPressed: _confirmSelection,
            icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
            label: Text(
              l10n.readPassage(rangeText),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerseStepper({
    required String label,
    required int? value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required Color accentColor,
    required Color textColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: accentColor,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onDecrement,
                icon: const Icon(Icons.remove_rounded),
                color: accentColor,
                iconSize: 20,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 36),
                child: Text(
                  value != null ? '$value' : '—',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: value != null
                        ? textColor
                        : textColor.withValues(alpha: 0.4),
                  ),
                ),
              ),
              IconButton(
                onPressed: onIncrement,
                icon: const Icon(Icons.add_rounded),
                color: accentColor,
                iconSize: 20,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
