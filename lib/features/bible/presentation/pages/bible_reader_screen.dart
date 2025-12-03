import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_controller.dart';
import 'package:fihirana/app/theme/font_controller.dart';
import 'package:fihirana/features/bible/presentation/widgets/bible_search_dialog.dart';
import 'package:fihirana/features/bible/presentation/widgets/bible_reader_widgets.dart';
import 'package:fihirana/features/bible/presentation/widgets/bible_settings_bottom_sheet_widget.dart';
import 'package:fihirana/shared/widgets/common/localization_extension.dart';
import 'package:fihirana/core/utils/translation_service.dart';
import 'package:fihirana/core/localization/language_controller.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  final BibleController bibleController = Get.put(BibleController());
  final ColorController colorController = Get.find<ColorController>();
  final FontController fontController = Get.find<FontController>();

  // Font settings
  double _fontSize = 18.0;
  String _fontFamily = 'Lato'; // Use font names from FontController

  // Scroll controller
  final ScrollController _verseScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('fontSize') ?? 18.0;
      _fontFamily = prefs.getString('fontFamily') ?? 'Serif';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setString('fontFamily', _fontFamily);
  }

  @override
  void dispose() {
    _verseScrollController.dispose();
    super.dispose();
  }

  TextStyle get _verseStyle {
    final color = colorController.textColor.value;
    return fontController.getFontStyle(
      _fontFamily,
      TextStyle(
        fontSize: _fontSize,
        color: color,
        height: 1.7,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final backgroundColor = colorController.backgroundColor.value;
      final iconColor = colorController.iconColor.value;
      final textColor = colorController.textColor.value;

      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              bibleController.selectedBook.isEmpty
                  ? Icons.menu_rounded
                  : Icons.arrow_back_ios_new_rounded,
              color: iconColor,
            ),
            onPressed: () {
              if (bibleController.selectedChapter.value > 0) {
                bibleController
                    .selectChapter(0); // Go back to chapter selection
              } else if (bibleController.selectedBook.isNotEmpty) {
                bibleController.selectBook(''); // Go back to book selection
              } else {
                Get.find<ShellController>().toggleDrawer();
              }
            },
          ),
          title: Text(
            _getAppBarTitle(),
            style: TextStyle(
              fontFamily: 'Roboto',
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.translate, color: iconColor),
              onPressed: _showTranslationDialog,
            ),
            IconButton(
              icon: Icon(Icons.search_rounded, color: iconColor),
              onPressed: _showSearchDialog,
            ),
            IconButton(
              icon: Icon(Icons.text_format_rounded, color: iconColor),
              onPressed: _showSettingsBottomSheet,
            ),
          ],
        ),
        body: _buildContentArea(),
      );
    });
  }

  String _getAppBarTitle() {
    if (bibleController.selectedBook.isNotEmpty &&
        bibleController.selectedChapter.value > 0) {
      return '${bibleController.selectedBook.value} ${bibleController.selectedChapter.value}';
    } else if (bibleController.selectedBook.isNotEmpty) {
      return bibleController.selectedBook.value;
    }
    return context.translate((l) => l.bibleReader);
  }

  Widget _buildContentArea() {
    return Obx(() {
      if (bibleController.selectedBook.isEmpty) {
        return _buildBookListView();
      } else if (bibleController.selectedChapter.value == 0) {
        return _buildChapterSelectionView();
      } else {
        return _buildVerseReadingView();
      }
    });
  }

  Widget _buildBookListView() {
    if (bibleController.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    final booksByTestament = bibleController.filteredBooks.isEmpty
        ? bibleController.booksByTestament
        : _getFilteredBooksByTestament();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: booksByTestament.length,
      itemBuilder: (context, index) {
        final testamentName = booksByTestament.keys.elementAt(index);
        final books = booksByTestament[testamentName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Text(
                testamentName.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: colorController.textColor.value.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...books.map((book) => BibleBookItemWidget(
                  bookName: book,
                  chapterCount: bibleController.getChapterCountForBook(book),
                  onTap: () => bibleController.selectBook(book),
                )),
          ],
        );
      },
    );
  }

  Widget _buildChapterSelectionView() {
    final chapters = bibleController.chapterList;
    if (chapters.isEmpty) {
      return Center(
        child: Text(
          context.translate((l) => l.noChaptersFound),
          style: TextStyle(color: colorController.textColor.value),
        ),
      );
    }

    return BibleChapterGridWidget(
      chapters: chapters,
      onChapterSelected: (chapter) => bibleController.selectChapter(chapter),
    );
  }

  Widget _buildVerseReadingView() {
    if (bibleController.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToHighlightedVerse();
    });

    final verses = bibleController.getCurrentChapterVerses();
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _verseScrollController,
                padding: const EdgeInsets.fromLTRB(
                    20, 16, 20, 100), // Add bottom padding for FAB
                itemCount:
                    verses.length + 1, // +1 for bottom spacing/navigation
                itemBuilder: (context, index) {
                  if (index == verses.length) {
                    return BibleChapterNavigationWidget(
                      onPrevious: () => _navigateChapter(-1),
                      onNext: () => _navigateChapter(1),
                    );
                  }
                  final verseNumber = index + 1;
                  final verseText = verses[index];
                  return BibleVerseItemWidget(
                    verseNumber: verseNumber,
                    verseText: verseText,
                    verseStyle: _verseStyle,
                    fontSize: _fontSize,
                    isSelected: bibleController.isVerseSelected(verseNumber),
                    isHighlighted:
                        bibleController.isVerseHighlighted(verseNumber),
                    isSearchHighlighted:
                        bibleController.isVerseSearchHighlighted(verseNumber),
                    onTap: () =>
                        bibleController.toggleVerseSelection(verseNumber),
                  );
                },
              ),
            ),
          ],
        ),
        // Selection Action Bar
        Obx(() {
          final l10n = AppLocalizations.of(context)!;
          if (!bibleController.isSelecting.value) {
            return const SizedBox.shrink();
          }

          return Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: colorController.backgroundColor.value,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color:
                      colorController.primaryColor.value.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Clear Selection
                  IconButton(
                    onPressed: () => bibleController.clearSelection(),
                    icon: Icon(Icons.close,
                        color: colorController.textColor.value),
                    tooltip: l10n.clear,
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color:
                        colorController.textColor.value.withValues(alpha: 0.2),
                  ),
                  // Highlight/Save
                  IconButton(
                    onPressed: () => bibleController.saveHighlight(),
                    icon: const Icon(Icons.highlight_rounded,
                        color: Colors.orange),
                    tooltip: l10n.saveChanges,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BibleSettingsBottomSheetWidget(
        fontSize: _fontSize,
        fontFamily: _fontFamily,
        onSettingsChanged: (fontSize, fontFamily) {
          setState(() {
            _fontSize = fontSize;
            _fontFamily = fontFamily;
          });
          _saveSettings();
        },
      ),
    );
  }

  // Helper methods
  Map<String, List<String>> _getFilteredBooksByTestament() {
    final filteredBooks = bibleController.filteredBooks;
    final allBooksByTestament = bibleController.booksByTestament;
    final result = <String, List<String>>{};

    for (final testamentName in allBooksByTestament.keys) {
      final testamentBooks = allBooksByTestament[testamentName]!;
      final filteredTestamentBooks =
          testamentBooks.where((book) => filteredBooks.contains(book)).toList();

      if (filteredTestamentBooks.isNotEmpty) {
        result[testamentName] = filteredTestamentBooks;
      }
    }
    return result;
  }

  void _navigateChapter(int direction) {
    final currentChapter = bibleController.selectedChapter.value;
    final newChapter = currentChapter + direction;
    final maxChapters = bibleController
        .getChapterCountForBook(bibleController.selectedBook.value);

    if (newChapter >= 1 && newChapter <= maxChapters) {
      bibleController.selectChapter(newChapter);
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const BibleSearchDialog(),
    );
  }

  void _scrollToHighlightedVerse() {
    final highlightedVerse = bibleController.highlightedVerse.value;
    if (highlightedVerse > 0 && _verseScrollController.hasClients) {
      // Approximate height calculation or use itemScrollController if needed
      // For now, simple offset estimation
      final verseHeight = _fontSize * 3; // Rough estimate
      final targetOffset = (highlightedVerse - 1) * verseHeight;

      _verseScrollController.animateTo(
        targetOffset.clamp(
            0.0, _verseScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _showTranslationDialog() async {
    if (bibleController.selectedBook.isEmpty ||
        bibleController.selectedChapter.value == 0) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final languageController = Get.find<LanguageController>();

    // Determine target language
    String targetLang = languageController.currentLocale.value.languageCode;
    if (targetLang == 'mg') {
      targetLang = 'en';
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final translationService = TranslationService();

      // Check if model is downloaded
      final isDownloaded =
          await translationService.isModelDownloaded(targetLang);

      if (!isDownloaded) {
        if (mounted) {
          Navigator.pop(context); // Close loading

          final shouldDownload = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.download),
              content: Text(
                  'Mila maka ny modelin\'ny teny $targetLang aloha. Te hanohy ve ianao?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.download),
                ),
              ],
            ),
          );

          if (shouldDownload != true) return;

          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            );
          }

          final success = await translationService.downloadModel(targetLang);
          if (!success) {
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.downloadFailed)),
              );
            }
            return;
          }
        }
      }

      // Translate verses
      final verses = bibleController.getCurrentChapterVerses();
      final List<String> translatedVerses = [];

      for (final verse in verses) {
        final translatedVerse = await translationService.translate(
          text: verse,
          sourceLanguage: 'mg', // Assuming Bible is in Malagasy
          targetLanguage: targetLang,
        );
        translatedVerses.add(translatedVerse);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Get.find<ColorController>().backgroundColor.value,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.viewTranslation,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Get.find<ColorController>().textColor.value,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: translatedVerses.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Get.find<ColorController>()
                                      .primaryColor
                                      .value
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  translatedVerses[index],
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Get.find<ColorController>()
                                        .textColor
                                        .value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorOccurred)),
        );
      }
    }
  }
}
