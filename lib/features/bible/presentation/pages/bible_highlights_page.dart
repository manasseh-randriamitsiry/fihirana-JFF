import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_highlight_controller.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_controller.dart';
import 'package:fihirana/features/bible/domain/entities/bible_highlight.dart';
import 'package:fihirana/l10n/app_localizations.dart';


class BibleHighlightsPage extends StatefulWidget {
  const BibleHighlightsPage({super.key});

  @override
  State<BibleHighlightsPage> createState() => _BibleHighlightsPageState();
}

class _BibleHighlightsPageState extends State<BibleHighlightsPage> {
  final ColorController colorController = Get.find<ColorController>();
  final BibleController bibleController = Get.find<BibleController>();
  late final BibleHighlightController highlightController;

  @override
  void initState() {
    super.initState();
    highlightController = Get.find<BibleHighlightController>();
    highlightController.loadAllUserHighlights();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorController.iconColor.value,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.savedVerses,
          style: TextStyle(
            fontFamily: 'Roboto',
            color: colorController.textColor.value,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Obx(() {
        final highlights = highlightController.allUserHighlights;

        if (highlights.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildHighlightsList(context, highlights);
      }),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 64,
            color: colorController.textColor.value.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noSavedVerses,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: colorController.textColor.value.withValues(alpha: 0.7),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.saveVersesByHighlighting,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: colorController.textColor.value.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightsList(BuildContext context, List<BibleHighlight> highlights) {
    // Group highlights by book
    final groupedHighlights = <String, List<BibleHighlight>>{};
    for (final highlight in highlights) {
      if (!groupedHighlights.containsKey(highlight.bookName)) {
        groupedHighlights[highlight.bookName] = [];
      }
      groupedHighlights[highlight.bookName]!.add(highlight);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedHighlights.length,
      itemBuilder: (context, index) {
        final bookName = groupedHighlights.keys.elementAt(index);
        final bookHighlights = groupedHighlights[bookName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                bookName,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: colorController.primaryColor.value,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...bookHighlights.map((highlight) => _buildHighlightItem(context, highlight)),
            if (index < groupedHighlights.length - 1) const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildHighlightItem(BuildContext context, BibleHighlight highlight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorController.primaryColor.value.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorController.primaryColor.value.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToHighlight(context, highlight),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getColorFromString(highlight.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${highlight.bookName} ${highlight.chapter}:${highlight.startVerse}${highlight.endVerse != highlight.startVerse ? '-$highlight.endVerse' : ''}',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: colorController.primaryColor.value,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: colorController.textColor.value.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    onPressed: () => _showDeleteDialog(context, highlight),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FutureBuilder<String>(
                future: _getVerseText(highlight),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      'Loading...',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: colorController.textColor.value.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    );
                  }

                  return Text(
                    snapshot.data ?? 'Verse not found',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: colorController.textColor.value.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'red':
        return Colors.red;
      case 'purple':
        return Colors.purple;
      default:
        return Colors.yellow;
    }
  }

  Future<String> _getVerseText(BibleHighlight highlight) async {
    try {
      final book = bibleController.bookController.getBook(highlight.bookName);
      if (book != null && book.chapterData.containsKey(highlight.chapter)) {
        final chapterData = book.chapterData[highlight.chapter]!;
        final verses = chapterData.verses;

        if (highlight.startVerse == highlight.endVerse) {
          return verses[highlight.startVerse] ?? 'Verse not found';
        } else {
          final verseTexts = <String>[];
          for (int i = highlight.startVerse; i <= highlight.endVerse; i++) {
            if (verses.containsKey(i)) {
              verseTexts.add('$i. ${verses[i]}');
            }
          }
          return verseTexts.join('\n\n');
        }
      }
    } catch (e) {
      // Handle error
    }
    return 'Verse not found';
  }

  void _navigateToHighlight(BuildContext context, BibleHighlight highlight) {
    // Navigate to the Bible reader and scroll to the highlight
    bibleController.selectBook(highlight.bookName);
    bibleController.selectChapter(highlight.chapter);
    bibleController.highlightedVerse.value = highlight.startVerse;

    // Close the highlights page
    Navigator.of(context).pop();

    // The BibleReaderScreen will handle scrolling to the highlighted verse
  }

  void _showDeleteDialog(BuildContext context, BibleHighlight highlight) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        title: Text(
          l10n.deleteHighlight,
          style: TextStyle(
            color: colorController.textColor.value,
            fontFamily: 'Roboto',
          ),
        ),
        content: Text(
          l10n.confirmDeleteHighlight,
          style: TextStyle(
            color: colorController.textColor.value.withValues(alpha: 0.8),
            fontFamily: 'Roboto',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.cancel,
              style: TextStyle(
                color: colorController.primaryColor.value,
                fontFamily: 'Roboto',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              highlightController.removeHighlight(highlight.id);
              Navigator.of(context).pop();
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(
                color: Colors.red,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ],
      ),
    );
  }
}