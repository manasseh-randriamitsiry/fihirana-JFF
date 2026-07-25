import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_controller.dart';
import 'package:fihirana/features/bible/di/bible_di.dart';
import 'package:fihirana/app/theme/font_controller.dart';
import 'package:fihirana/features/bible/presentation/widgets/bible_search_dialog.dart';
import 'package:fihirana/features/bible/presentation/widgets/bible_reader_widgets.dart';
import 'package:fihirana/features/bible/presentation/widgets/bible_settings_bottom_sheet_widget.dart';
import 'package:fihirana/features/bible/presentation/widgets/bible_selection_action_bar_widget.dart';
import 'package:fihirana/features/bible/presentation/pages/bible_highlights_page.dart';
import 'package:fihirana/features/bible/presentation/widgets/bible_verse_selection_sheet.dart';
import 'package:fihirana/shared/widgets/common/localization_extension.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';

class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  late final BibleController bibleController;

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
    BibleDI.init();
    bibleController = Get.find<BibleController>();
    _loadSettings();

    // Listen for changes to highlightedVerse to scroll to it
    ever(bibleController.highlightedVerse, (verse) {
      if (verse > 0) {
        _scrollToHighlightedVerse();
      }
    });
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
    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Obx(() => IconButton(
              icon: Icon(
                bibleController.selectedBook.isEmpty
                    ? Icons.menu_rounded
                    : Icons.arrow_back_ios_new_rounded,
                color: colorController.iconColor.value,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                if (bibleController.selectedChapter > 0) {
                  bibleController
                      .selectChapter(0); // Go back to chapter selection
                } else if (bibleController.selectedBook.isNotEmpty) {
                  bibleController.selectBook(''); // Go back to book selection
                } else {
                  Get.find<ShellController>().toggleDrawer();
                }
              },
            )),
        title: Obx(() => Text(
              _getAppBarTitle(context),
              style: TextStyle(
                fontFamily: 'Roboto',
                color: colorController.textColor.value,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            )),
        actions: [
          if (AuthController.instance.isAuthenticated)
            IconButton(
              icon: Icon(Icons.bookmark_rounded,
                  color: colorController.iconColor.value),
              onPressed: () {
                HapticFeedback.lightImpact();
                _showHighlightsPage(context);
              },
            ),
          IconButton(
            icon: Icon(Icons.search_rounded,
                color: colorController.iconColor.value),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showSearchDialog(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.text_format_rounded,
                color: colorController.iconColor.value),
            onPressed: () {
              HapticFeedback.lightImpact();
              _showSettingsBottomSheet(context);
            },
          ),
        ],
      ),
      body: Obx(() => _buildContentArea(context)),
    );
  }

  String _getAppBarTitle(BuildContext context) {
    if (bibleController.selectedBook.isEmpty &&
        bibleController.selectedChapter > 0) {
      return '${bibleController.selectedBook} ${bibleController.selectedChapter}';
    } else if (bibleController.selectedBook.isNotEmpty) {
      return bibleController.selectedBook;
    }
    return context.translate((l) => l.bibleReader);
  }

  Widget _buildContentArea(BuildContext context) {
    if (bibleController.selectedBook.isEmpty) {
      return _buildBookListView();
    } else if (bibleController.selectedChapter == 0) {
      return _buildChapterSelectionView(context);
    } else {
      return _buildVerseReadingView(context);
    }
  }

  Widget _buildBookListView() {
    if (bibleController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final booksByTestament = bibleController.filteredBooks.isEmpty
        ? bibleController.booksByTestament
        : _getFilteredBooksByTestament();

    return ListView.builder(
      key: const PageStorageKey('bible_books_list'),
      cacheExtent: 1200.0,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: booksByTestament.length,
      itemBuilder: (context, index) {
        final testamentName = booksByTestament.keys.elementAt(index);
        final books = booksByTestament[testamentName]!;

        return Column(
          key: ValueKey(testamentName),
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

  Widget _buildChapterSelectionView(BuildContext context) {
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
      onChapterSelected: (chapter) =>
          _showVerseSelectionSheet(context, chapter),
    );
  }

  void _showVerseSelectionSheet(BuildContext context, int chapter) {
    final bookName = bibleController.selectedBook;
    final totalVerses =
        bibleController.getVerseCountForChapter(bookName, chapter);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BibleVerseSelectionSheet(
        bookName: bookName,
        chapter: chapter,
        totalVerses: totalVerses,
        onReadVerses: (startVerse, endVerse) {
          if (startVerse == 1 && endVerse == totalVerses) {
            bibleController.highlightedVerse.value = 0;
            bibleController.selectChapter(chapter);
          } else {
            bibleController.selectChapterWithVerseRange(
                chapter, startVerse, endVerse);
          }
        },
      ),
    );
  }

  Widget _buildVerseReadingView(BuildContext context) {
    if (bibleController.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final verses = bibleController.getCurrentChapterVerses();
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Obx(() {
                final highlightedVerse = bibleController.highlightedVerse.value;
                final selectedVersesSet = bibleController.selectedVerses.toSet();

                return ListView.builder(
                  key: const PageStorageKey('bible_verses_list'),
                  controller: _verseScrollController,
                  cacheExtent: 1200.0,
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
                    final isSelected = selectedVersesSet.contains(verseNumber);

                    return BibleVerseItemWidget(
                      key: ValueKey(verseNumber),
                      verseNumber: verseNumber,
                      verseText: verseText,
                      verseStyle: _verseStyle,
                      fontSize: _fontSize,
                      highlightedVerse: highlightedVerse,
                      isSelected: isSelected,
                      isHighlighted:
                          bibleController.isVerseHighlighted(verseNumber),
                      isSearchHighlighted:
                          bibleController.isVerseSearchHighlighted(verseNumber),
                      onTap: () {
                        // Clear the highlighted verse when user interacts
                        bibleController.highlightedVerse.value = 0;
                        bibleController.toggleVerseSelection(verseNumber);
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
        const BibleSelectionActionBarWidget(),
      ],
    );
  }

  void _onSettingsChanged(double fontSize, String fontFamily) {
    setState(() {
      _fontSize = fontSize;
      _fontFamily = fontFamily;
    });
    _saveSettings();
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BibleSettingsBottomSheetWidget(
        fontSize: _fontSize,
        fontFamily: _fontFamily,
        onSettingsChanged: _onSettingsChanged,
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
    final currentChapter = bibleController.selectedChapter;
    final newChapter = currentChapter + direction;
    final maxChapters =
        bibleController.getChapterCountForBook(bibleController.selectedBook);

    if (newChapter >= 1 && newChapter <= maxChapters) {
      // Clear highlighted verse when navigating to different chapter
      bibleController.highlightedVerse.value = 0;
      bibleController.selectChapter(newChapter);
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const BibleSearchDialog(),
    );
  }

  void _showHighlightsPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BibleHighlightsPage(),
      ),
    );
  }

  void _scrollToHighlightedVerse() {
    final highlightedVerse = bibleController.highlightedVerse.value;
    if (highlightedVerse > 0 && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!_verseScrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) _scrollToHighlightedVerse();
          });
          return;
        }

        // Better height estimation considering padding and line height
        // Average verse takes about 80-120 pixels depending on length
        final estimatedVerseHeight = _fontSize * 5; // More accurate estimate
        final targetOffset = (highlightedVerse - 1) * estimatedVerseHeight;

        final maxScroll = _verseScrollController.position.maxScrollExtent;
        final clampedOffset = targetOffset.clamp(0.0, maxScroll);

        _verseScrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );

        // Clear the highlighted verse after a longer delay to let user see the target verse
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted) {
            bibleController.highlightedVerse.value = 0;
          }
        });
      });
    }
  }
}
