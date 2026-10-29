import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/design_system/app_scale.dart';

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
    final colors = Theme.of(context).colorScheme;
    final primaryColor = colors.primary;
    final backgroundColor = colors.surface;
    final textColor = colors.onSurface;

    final startColor = primaryColor;
    final endColor = colors.secondary;

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
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppScale.radiusFloat)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppScale.gutter, AppScale.space12, AppScale.gutter, AppScale.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppScale.space16),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppScale.radiusMark),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppScale.space12),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppScale.radiusRow),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppScale.space16),
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

          const SizedBox(height: AppScale.space16),

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
              padding: const EdgeInsets.symmetric(
                  horizontal: AppScale.space24, vertical: AppScale.space12),
              side: BorderSide(color: primaryColor.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppScale.radiusRow),
              ),
            ),
          ),

          const SizedBox(height: AppScale.space16),

          // Divider with label
          Row(
            children: [
              Expanded(
                  child: Divider(color: textColor.withValues(alpha: 0.15))),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppScale.space12),
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

          const SizedBox(height: AppScale.space12),

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

          const SizedBox(height: AppScale.space16),

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
                    padding:
                        const EdgeInsets.symmetric(vertical: AppScale.space4),
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
                        itemFg = colors.onPrimary;
                      } else if (isEnd) {
                        itemBg = endColor;
                        itemFg = colors.onSecondary;
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
                        borderRadius:
                            BorderRadius.circular(AppScale.radiusControl),
                        child: Container(
                          decoration: BoxDecoration(
                            color: itemBg,
                            borderRadius:
                                BorderRadius.circular(AppScale.radiusControl),
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

          const SizedBox(height: AppScale.space16),

          // Bottom CTA Button
          ElevatedButton.icon(
            onPressed: _confirmSelection,
            icon: Icon(Icons.menu_book_rounded, color: colors.onPrimary),
            label: Text(
              l10n.readPassage(rangeText),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.onPrimary,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppScale.space24, vertical: AppScale.space12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppScale.radiusRow),
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
        const SizedBox(height: AppScale.space4),
        Container(
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppScale.radiusRow),
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
