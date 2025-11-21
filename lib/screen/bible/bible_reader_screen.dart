import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/color_controller.dart';
import '../../controller/bible_controller.dart';
import '../../controller/font_controller.dart';
import '../../widgets/bible_search_dialog.dart';
import '../../l10n/app_localizations.dart';

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
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor),
            onPressed: () {
              if (bibleController.selectedChapter.value > 0) {
                bibleController
                    .selectChapter(0); // Go back to chapter selection
              } else if (bibleController.selectedBook.isNotEmpty) {
                bibleController.selectBook(''); // Go back to book selection
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            _getAppBarTitle(),
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
          actions: [
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
    final l10n = AppLocalizations.of(context)!;
    if (bibleController.selectedBook.isNotEmpty &&
        bibleController.selectedChapter.value > 0) {
      return '${bibleController.selectedBook.value} ${bibleController.selectedChapter.value}';
    } else if (bibleController.selectedBook.isNotEmpty) {
      return bibleController.selectedBook.value;
    }
    return l10n.bibleReader;
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
                style: GoogleFonts.inter(
                  color: colorController.textColor.value.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...books.map((book) => _buildBookItem(book)),
          ],
        );
      },
    );
  }

  Widget _buildBookItem(String bookName) {
    final chapterCount = bibleController.getChapterCountForBook(bookName);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorController.primaryColor.value.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () => bibleController.selectBook(bookName),
        title: Text(
          bookName,
          style: GoogleFonts.inter(
            color: colorController.textColor.value,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colorController.primaryColor.value.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$chapterCount',
            style: TextStyle(
              color: colorController.primaryColor.value,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildChapterSelectionView() {
    final chapters = bibleController.chapterList;
    if (chapters.isEmpty) {
      return Center(
        child: Text(
          'No chapters found',
          style: TextStyle(color: colorController.textColor.value),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: chapters.length,
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return InkWell(
          onTap: () => bibleController.selectChapter(chapter),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: colorController.primaryColor.value.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorController.primaryColor.value.withOpacity(0.2),
              ),
            ),
            child: Center(
              child: Text(
                '$chapter',
                style: GoogleFonts.inter(
                  color: colorController.primaryColor.value,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      },
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
                    return _buildChapterNavigation();
                  }
                  final verseNumber = index + 1;
                  final verseText = verses[index];
                  return _buildVerseItem(verseNumber, verseText);
                },
              ),
            ),
          ],
        ),
        // Selection Action Bar
        Obx(() {
          if (!bibleController.isSelecting.value)
            return const SizedBox.shrink();

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
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: colorController.primaryColor.value.withOpacity(0.1),
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
                    tooltip: 'Manafoana',
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: colorController.textColor.value.withOpacity(0.2),
                  ),
                  // Highlight/Save
                  IconButton(
                    onPressed: () => bibleController.saveHighlight(),
                    icon: const Icon(Icons.highlight_rounded,
                        color: Colors.orange),
                    tooltip: 'Marihina',
                  ),
                  // Copy (Optional, can be added later)
                  /*
                  IconButton(
                    onPressed: () {
                      // Implement copy functionality
                    },
                    icon: Icon(Icons.copy_rounded, color: colorController.primaryColor.value),
                    tooltip: 'Adika',
                  ),
                  */
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildVerseItem(int verseNumber, String verseText) {
    return Obx(() {
      final isSelected = bibleController.isVerseSelected(verseNumber);
      final isHighlighted = bibleController.isVerseHighlighted(verseNumber);
      final isSearchHighlighted =
          bibleController.isVerseSearchHighlighted(verseNumber);

      Color backgroundColor = Colors.transparent;
      if (isSearchHighlighted) {
        backgroundColor = Colors.yellow.withOpacity(0.3);
      } else if (isSelected) {
        backgroundColor = colorController.primaryColor.value.withOpacity(0.15);
      } else if (isHighlighted) {
        backgroundColor = colorController.primaryColor.value.withOpacity(0.05);
      }

      return GestureDetector(
        onTap: () => bibleController.toggleVerseSelection(verseNumber),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$verseNumber ',
                  style: GoogleFonts.inter(
                    color: colorController.primaryColor.value,
                    fontSize: _fontSize * 0.7,
                    fontWeight: FontWeight.bold,
                    fontFeatures: [const FontFeature.superscripts()],
                  ),
                ),
                TextSpan(
                  text: verseText,
                  style: _verseStyle,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildChapterNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () => _navigateChapter(-1),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Previous'),
            style: TextButton.styleFrom(
              foregroundColor: colorController.textColor.value,
            ),
          ),
          TextButton.icon(
            onPressed: () => _navigateChapter(1),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Next'),
            style: TextButton.styleFrom(
              foregroundColor: colorController.textColor.value,
            ),
            iconAlignment: IconAlignment.end,
          ),
        ],
      ),
    );
  }

  void _showSettingsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: colorController.backgroundColor.value,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Appearance',
                style: GoogleFonts.inter(
                  color: colorController.textColor.value,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              // Font Size
              Row(
                children: [
                  Icon(Icons.text_fields,
                      size: 20, color: colorController.textColor.value),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 12,
                      max: 32,
                      activeColor: colorController.primaryColor.value,
                      onChanged: (value) {
                        setState(() => _fontSize = value);
                        setModalState(() {}); // Update modal state
                      },
                      onChangeEnd: (value) => _saveSettings(),
                    ),
                  ),
                  Text(
                    '${_fontSize.toInt()}',
                    style: TextStyle(color: colorController.textColor.value),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Font Family Selector
              Text(
                'Font Family (${fontController.availableFonts.length} fonts)',
                style: GoogleFonts.inter(
                  color: colorController.textColor.value,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: fontController.availableFonts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final fontName = fontController.availableFonts[index];
                    return _buildHorizontalFontOption(
                      fontName,
                      fontName,
                      setModalState,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Theme
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildThemeOption(
                      ThemeMode.light, Icons.light_mode_rounded, 'Light'),
                  _buildThemeOption(
                      ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalFontOption(
      String family, String fontName, StateSetter setModalState) {
    final isSelected = _fontFamily == family;
    return GestureDetector(
      onTap: () {
        setState(() => _fontFamily = family);
        setModalState(() {});
        _saveSettings();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorController.primaryColor.value
              : colorController.primaryColor.value.withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? colorController.primaryColor.value
                : colorController.textColor.value.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          fontName,
          style: fontController.getFontStyle(
            fontName,
            TextStyle(
              color:
                  isSelected ? Colors.white : colorController.textColor.value,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(ThemeMode mode, IconData icon, String label) {
    return Obx(() {
      final isSelected = colorController.themeMode == mode;
      return GestureDetector(
        onTap: () => colorController.setThemeMode(mode),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? colorController.primaryColor.value
                    : colorController.textColor.value.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                color:
                    isSelected ? Colors.white : colorController.textColor.value,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: colorController.textColor.value,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    });
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
}
