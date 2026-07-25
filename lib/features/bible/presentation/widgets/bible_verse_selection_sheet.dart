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
  late int _startVerse;
  late int _endVerse;
  bool _isRangeSelectionActive = false;

  @override
  void initState() {
    super.initState();
    _startVerse = 1;
    _endVerse = widget.totalVerses > 0 ? widget.totalVerses : 1;
  }

  void _onVerseTap(int verseNumber) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_isRangeSelectionActive) {
        // First tap: set single verse start and end
        _startVerse = verseNumber;
        _endVerse = verseNumber;
        _isRangeSelectionActive = true;
      } else {
        // Second tap: set range
        if (verseNumber < _startVerse) {
          _endVerse = _startVerse;
          _startVerse = verseNumber;
        } else {
          _endVerse = verseNumber;
        }
        _isRangeSelectionActive = false; // Reset for next range selection
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
    widget.onReadVerses(_startVerse, _endVerse);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorController = Get.find<ColorController>();
    final primaryColor = colorController.primaryColor.value;
    final backgroundColor = colorController.backgroundColor.value;
    final textColor = colorController.textColor.value;

    final isSingleVerse = _startVerse == _endVerse;
    final isFullChapter = _startVerse == 1 && _endVerse == widget.totalVerses;

    final rangeText = isFullChapter
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
              // Start Verse Selector
              _buildVerseStepper(
                label: l10n.fromVerse,
                value: _startVerse,
                onDecrement: () {
                  if (_startVerse > 1) {
                    setState(() {
                      _startVerse--;
                      if (_endVerse < _startVerse) _endVerse = _startVerse;
                    });
                  }
                },
                onIncrement: () {
                  if (_startVerse < widget.totalVerses) {
                    setState(() {
                      _startVerse++;
                      if (_endVerse < _startVerse) _endVerse = _startVerse;
                    });
                  }
                },
                primaryColor: primaryColor,
                textColor: textColor,
              ),

              Icon(
                Icons.arrow_forward_rounded,
                color: textColor.withValues(alpha: 0.3),
                size: 20,
              ),

              // End Verse Selector
              _buildVerseStepper(
                label: l10n.toVerse,
                value: _endVerse,
                onDecrement: () {
                  if (_endVerse > _startVerse) {
                    setState(() {
                      _endVerse--;
                    });
                  }
                },
                onIncrement: () {
                  if (_endVerse < widget.totalVerses) {
                    setState(() {
                      _endVerse++;
                    });
                  }
                },
                primaryColor: primaryColor,
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
                      final isStart = verse == _startVerse;
                      final isEnd = verse == _endVerse;
                      final inRange =
                          verse >= _startVerse && verse <= _endVerse;

                      Color itemBg;
                      Color itemFg;
                      Border? border;

                      if (isStart || isEnd) {
                        itemBg = primaryColor;
                        itemFg = Colors.white;
                      } else if (inRange) {
                        itemBg = primaryColor.withValues(alpha: 0.25);
                        itemFg = primaryColor;
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
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required Color primaryColor,
    required Color textColor,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onDecrement,
                icon: const Icon(Icons.remove_rounded),
                color: primaryColor,
                iconSize: 20,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 36),
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: onIncrement,
                icon: const Icon(Icons.add_rounded),
                color: primaryColor,
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
