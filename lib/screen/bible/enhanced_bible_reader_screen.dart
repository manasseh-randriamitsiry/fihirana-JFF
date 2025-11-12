import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controller/color_controller.dart';
import '../../controller/bible_controller.dart';
import '../../models/bible_search.dart';
import '../../widgets/bible_book_list_item.dart';
import '../../widgets/color_picker_widget.dart';
import '../../l10n/app_localizations.dart';

class EnhancedBibleReaderScreen extends StatefulWidget {
  const EnhancedBibleReaderScreen({super.key});

  @override
  State<EnhancedBibleReaderScreen> createState() =>
      _EnhancedBibleReaderScreenState();
}

class _EnhancedBibleReaderScreenState extends State<EnhancedBibleReaderScreen>
    with TickerProviderStateMixin {
  final BibleController bibleController = Get.put(BibleController());
  final ColorController colorController = Get.find<ColorController>();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Font size variables
  final double _baseFontSize = 18.0;
  final double _baseCountFontSize = 50.0;
  double _fontSize = 18.0;
  double _countFontSize = 50.0;
  bool _showSlider = false;
  bool _showSearchBar = false;
  BibleSearchContext _currentSearchContext = BibleSearchContext.books;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFontSize();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _animationController.forward();
  }

  void _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('fontSize') ?? _baseFontSize;
      _countFontSize = prefs.getDouble('countFontSize') ?? _baseCountFontSize;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GetBuilder<ColorController>(
      builder: (colorController) => NeumorphicTheme(
        themeMode: colorController.themeMode,
        theme: colorController.getNeumorphicLightTheme(),
        darkTheme: colorController.getNeumorphicDarkTheme(),
        child: Scaffold(
          backgroundColor: colorController.backgroundColor.value,
          body: SafeArea(
            child: Column(
              children: [
                _buildNeumorphicAppBar(colorController),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Obx(() => _buildContentArea(colorController)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicAppBar(ColorController colorController) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Neumorphic(
          style: NeumorphicStyle(
            depth: 4,
            intensity: 0.8,
            color: colorController.backgroundColor.value,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Back button
                NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: 2,
                    color: colorController.backgroundColor.value,
                    boxShape: NeumorphicBoxShape.circle(),
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: colorController.iconColor.value,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),

                // Title
                Expanded(
                  child: Obx(() {
                    final l10n = AppLocalizations.of(context)!;
                    if (bibleController.selectedBook.isNotEmpty &&
                        bibleController.selectedChapter.value > 0) {
                      return Text(
                        '${bibleController.selectedBook.value} ${bibleController.selectedChapter.value}',
                        style: TextStyle(
                          color: colorController.textColor.value,
                          fontWeight: FontWeight.bold,
                          fontSize: _fontSize * 1.1,
                        ),
                      );
                    } else {
                      return Text(
                        l10n.bibleReader,
                        style: TextStyle(
                          color: colorController.textColor.value,
                          fontWeight: FontWeight.bold,
                          fontSize: _fontSize * 1.1,
                        ),
                      );
                    }
                  }),
                ),

                // Search button
                NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: 2,
                    color: colorController.backgroundColor.value,
                    boxShape: NeumorphicBoxShape.circle(),
                  ),
                  child: Icon(
                    _showSearchBar ? Icons.close : Icons.search,
                    color: colorController.iconColor.value,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _showSearchBar = !_showSearchBar;
                      if (_showSearchBar) {
                        // Request focus when opening search
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _searchFocusNode.requestFocus();
                        });
                      } else {
                        // Clear search and unfocus when closing
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                        bibleController.filterBooks('');
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),

                // Font size button
                NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: 2,
                    color: colorController.backgroundColor.value,
                    boxShape: NeumorphicBoxShape.circle(),
                  ),
                  child: Icon(
                    Icons.text_fields,
                    color: colorController.iconColor.value,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _showSlider = !_showSlider;
                    });
                  },
                ),
                const SizedBox(width: 8),

                // Color picker button
                NeumorphicButton(
                  style: NeumorphicStyle(
                    depth: 2,
                    color: colorController.backgroundColor.value,
                    boxShape: NeumorphicBoxShape.circle(),
                  ),
                  child: Icon(
                    Icons.color_lens,
                    color: colorController.iconColor.value,
                    size: 20,
                  ),
                  onPressed: () {
                    ColorPickerWidget.showColorPickerDialog(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea(ColorController colorController) {
    final selectedBook = bibleController.selectedBook.value;
    final selectedChapter = bibleController.selectedChapter.value;
    final hasChapters = bibleController.chapterList.isNotEmpty;

    // Update search context based on current view
    _updateSearchContext();

    // If search is active, show search results
    if (_showSearchBar && bibleController.searchQuery.value.isNotEmpty) {
      return _buildSearchResultsView(colorController);
    }

    // If no book selected, show book list
    if (selectedBook.isEmpty) {
      if (_showSearchBar) {
        return Column(
          children: [
            _buildNeumorphicSearchBar(colorController),
            Expanded(child: _buildBookListView(colorController)),
          ],
        );
      } else {
        return _buildBookListView(colorController);
      }
    }

    // If book selected but no chapter, show chapter selection
    if (selectedChapter == 0) {
      if (_showSearchBar) {
        return Column(
          children: [
            _buildNeumorphicSearchBar(colorController),
            Expanded(child: _buildChapterSelectionView(colorController)),
          ],
        );
      } else {
        return _buildChapterSelectionView(colorController);
      }
    }

    // If chapter selected, show verse reading view
    if (_showSearchBar) {
      return Column(
        children: [
          _buildNeumorphicSearchBar(colorController),
          Expanded(child: _buildVerseReadingView(colorController)),
        ],
      );
    } else {
      return _buildVerseReadingView(colorController);
    }
  }

  Widget _buildNeumorphicSearchBar(ColorController colorController) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(16),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 3,
          intensity: 0.8,
          color: colorController.backgroundColor.value,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        ),
        child: Column(
          children: [
            // Search context selector
            if (_currentSearchContext != BibleSearchContext.books)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorController.iconColor.value,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getSearchContextText(l10n),
                        style: TextStyle(
                          color:
                              colorController.textColor.value.withOpacity(0.7),
                          fontSize: _fontSize * 0.8,
                        ),
                      ),
                    ),
                    NeumorphicButton(
                      style: NeumorphicStyle(
                        depth: 1,
                        color: colorController.backgroundColor.value,
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(8)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      onPressed: () =>
                          _showSearchContextDialog(colorController),
                      child: Text(
                        l10n.change,
                        style: TextStyle(
                          color: colorController.primaryColor.value,
                          fontSize: _fontSize * 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Search input
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: TextStyle(
                  color: colorController.textColor.value,
                  fontSize: _fontSize,
                ),
                decoration: InputDecoration(
                  hintText: _getSearchHintText(l10n),
                  hintStyle: TextStyle(
                    color: colorController.textColor.value.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorController.iconColor.value,
                  ),
                  suffixIcon: bibleController.searchQuery.value.isNotEmpty
                      ? NeumorphicButton(
                          style: NeumorphicStyle(
                            depth: 1,
                            color: colorController.backgroundColor.value,
                            boxShape: NeumorphicBoxShape.circle(),
                          ),
                          child: Icon(
                            Icons.clear,
                            color: colorController.iconColor.value,
                            size: 16,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            bibleController.performSearch('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (value) {
                  bibleController.performSearch(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSearchContextText(AppLocalizations l10n) {
    switch (_currentSearchContext) {
      case BibleSearchContext.books:
        return l10n.searchBooks;
      case BibleSearchContext.currentChapter:
        return l10n.searchCurrentChapter(
            bibleController.selectedChapter.value.toString());
      case BibleSearchContext.allBible:
        return l10n.searchEntireBible;
    }
  }

  String _getSearchHintText(AppLocalizations l10n) {
    switch (_currentSearchContext) {
      case BibleSearchContext.books:
        return l10n.searchBooks;
      case BibleSearchContext.currentChapter:
        return l10n.searchCurrentChapter(
            bibleController.selectedChapter.value.toString());
      case BibleSearchContext.allBible:
        return l10n.searchEntireBible;
    }
  }

  void _showSearchContextDialog(ColorController colorController) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Neumorphic(
            style: NeumorphicStyle(
              depth: 4,
              color: colorController.backgroundColor.value,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Safidio ny karoka',
                    style: TextStyle(
                      color: colorController.textColor.value,
                      fontSize: _fontSize * 1.2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...BibleSearchContext.values.map((context) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NeumorphicButton(
                        style: NeumorphicStyle(
                          depth: 2,
                          color: _currentSearchContext == context
                              ? colorController.primaryColor.value
                              : colorController.backgroundColor.value,
                        ),
                        padding: const EdgeInsets.all(16),
                        onPressed: () {
                          _currentSearchContext = context;
                          bibleController.setSearchContext(context);
                          Get.back();
                        },
                        child: Row(
                          children: [
                            Icon(
                              _getSearchContextIcon(context),
                              color: _currentSearchContext == context
                                  ? Colors.white
                                  : colorController.textColor.value,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _getSearchContextTitle(context),
                                style: TextStyle(
                                  color: _currentSearchContext == context
                                      ? Colors.white
                                      : colorController.textColor.value,
                                  fontSize: _fontSize,
                                ),
                              ),
                            ),
                            if (_currentSearchContext == context)
                              Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSearchContextIcon(BibleSearchContext context) {
    switch (context) {
      case BibleSearchContext.books:
        return Icons.book;
      case BibleSearchContext.currentChapter:
        return Icons.article;
      case BibleSearchContext.allBible:
        return Icons.menu_book;
    }
  }

  String _getSearchContextTitle(BibleSearchContext context) {
    switch (context) {
      case BibleSearchContext.books:
        return 'Boky iray';
      case BibleSearchContext.currentChapter:
        return 'Toko misy anko';
      case BibleSearchContext.allBible:
        return 'Baiboly manontolo';
    }
  }

  Widget _buildBookListView(ColorController colorController) {
    return Column(
      children: [
        // Font size slider
        if (_showSlider) _buildNeumorphicFontSizeSlider(colorController),

        // Books grid
        Expanded(
          child: Obx(() {
            if (bibleController.isLoading.value) {
              return _buildLoadingWidget(colorController);
            }

            final filteredBooks = bibleController.filteredBooks.isEmpty
                ? bibleController.bookList
                : bibleController.filteredBooks;

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: GridView.builder(
                key: ValueKey(filteredBooks.length),
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: filteredBooks.length,
                itemBuilder: (context, index) {
                  final bookName = filteredBooks[index];
                  final chapterCount =
                      bibleController.getChapterCountForBook(bookName);

                  return _buildNeumorphicBookItem(
                    bookName: bookName,
                    chapterCount: chapterCount,
                    colorController: colorController,
                    onTap: () => bibleController.selectBook(bookName),
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildNeumorphicBookItem({
    required String bookName,
    required int chapterCount,
    required ColorController colorController,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: NeumorphicButton(
        style: NeumorphicStyle(
          depth: 3,
          intensity: 0.8,
          color: colorController.backgroundColor.value,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        ),
        padding: const EdgeInsets.all(16),
        onPressed: () {
          print('Book item pressed: $bookName');
          onTap();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              bookName,
              style: TextStyle(
                color: colorController.textColor.value,
                fontSize: _fontSize * 0.9,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$chapterCount toko',
              style: TextStyle(
                color: colorController.textColor.value.withOpacity(0.7),
                fontSize: _fontSize * 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterSelectionView(ColorController colorController) {
    print('Building chapter selection view');
    return Column(
      children: [
        // Header with book info
        _buildChapterHeader(colorController),

        // Font size slider
        if (_showSlider) _buildNeumorphicFontSizeSlider(colorController),

        // Chapter grid
        Expanded(
          child: Obx(() {
            print('Chapter list in Obx: ${bibleController.chapterList}');
            if (bibleController.chapterList.isEmpty) {
              print('Chapter list is empty, showing empty message');
              return Center(
                child: Text(
                  'Tsy misy toko',
                  style: TextStyle(
                    color: colorController.textColor.value,
                    fontSize: _fontSize,
                  ),
                ),
              );
            }

            print(
                'Building grid with ${bibleController.chapterList.length} chapters');
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: bibleController.chapterList.length,
              itemBuilder: (context, index) {
                final chapter = bibleController.chapterList[index];
                return _buildNeumorphicChapterItem(
                  chapter: chapter,
                  colorController: colorController,
                  onTap: () => bibleController.selectChapter(chapter),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildChapterHeader(ColorController colorController) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 3,
          intensity: 0.8,
          color: colorController.primaryColor.value.withOpacity(0.1),
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 2,
                  color: colorController.backgroundColor.value,
                  boxShape: NeumorphicBoxShape.circle(),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: colorController.iconColor.value,
                  size: 20,
                ),
                onPressed: () {
                  bibleController.selectedBook.value = '';
                  bibleController.chapterList.clear();
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  bibleController.selectedBook.value,
                  style: TextStyle(
                    color: colorController.textColor.value,
                    fontSize: _fontSize * 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicChapterItem({
    required int chapter,
    required ColorController colorController,
    required VoidCallback onTap,
  }) {
    return NeumorphicButton(
      style: NeumorphicStyle(
        depth: 3,
        intensity: 0.8,
        color: colorController.primaryColor.value,
        boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Center(
        child: Text(
          chapter.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildVerseReadingView(ColorController colorController) {
    return Column(
      children: [
        // Chapter navigation
        _buildChapterNavigation(colorController),

        // Font size slider
        if (_showSlider) _buildNeumorphicFontSizeSlider(colorController),

        // Verses
        Expanded(
          child: Obx(() {
            if (bibleController.isLoading.value) {
              return _buildLoadingWidget(colorController);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildVersesList(colorController),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildChapterNavigation(ColorController colorController) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 3,
          intensity: 0.8,
          color: colorController.backgroundColor.value,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous chapter
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 2,
                  color: colorController.backgroundColor.value,
                  boxShape: NeumorphicBoxShape.circle(),
                ),
                child: Icon(
                  Icons.keyboard_arrow_left,
                  color: colorController.iconColor.value,
                ),
                onPressed: () => _navigateChapter(-1),
              ),

              // Current chapter
              Text(
                'Toko ${bibleController.selectedChapter.value}',
                style: TextStyle(
                  color: colorController.textColor.value,
                  fontSize: _fontSize * 1.1,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Next chapter
              NeumorphicButton(
                style: NeumorphicStyle(
                  depth: 2,
                  color: colorController.backgroundColor.value,
                  boxShape: NeumorphicBoxShape.circle(),
                ),
                child: Icon(
                  Icons.keyboard_arrow_right,
                  color: colorController.iconColor.value,
                ),
                onPressed: () => _navigateChapter(1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersesList(ColorController colorController) {
    final verses = bibleController.getCurrentChapterVerses();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chapter header
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Neumorphic(
            style: NeumorphicStyle(
              depth: 2,
              intensity: 0.6,
              color: colorController.primaryColor.value.withOpacity(0.1),
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${bibleController.selectedBook.value} ${bibleController.selectedChapter.value}',
                style: TextStyle(
                  color: colorController.textColor.value,
                  fontSize: _fontSize * 1.3,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        // Verses
        ...verses.asMap().entries.map((entry) {
          final index = entry.key;
          final verse = entry.value;
          final verseNumber = index + 1;

          return _buildNeumorphicVerse(
            verseNumber: verseNumber,
            verseText: verse,
            colorController: colorController,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildNeumorphicVerse({
    required int verseNumber,
    required String verseText,
    required ColorController colorController,
  }) {
    return Obx(() {
      final isSelected = bibleController.isVerseSelected(verseNumber);
      final isHighlighted = bibleController.isVerseHighlighted(verseNumber);

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: NeumorphicButton(
          style: NeumorphicStyle(
            depth: isSelected ? 1 : 2,
            intensity: 0.8,
            color: isHighlighted
                ? colorController.primaryColor.value.withOpacity(0.2)
                : colorController.backgroundColor.value,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
          ),
          padding: const EdgeInsets.all(16),
          onPressed: () => bibleController.toggleVerseSelection(verseNumber),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Verse number
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorController.primaryColor.value
                      : colorController.primaryColor.value.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    verseNumber.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : colorController.primaryColor.value,
                      fontSize: _fontSize * 0.7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Verse text
              Expanded(
                child: Text(
                  verseText,
                  style: TextStyle(
                    color: colorController.textColor.value,
                    fontSize: _fontSize,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildNeumorphicFontSizeSlider(ColorController colorController) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 3,
          intensity: 0.8,
          color: colorController.backgroundColor.value,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Habeo ny endri-tsoratra',
                    style: TextStyle(
                      color: colorController.textColor.value,
                      fontSize: _fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_fontSize.round()}',
                    style: TextStyle(
                      color: colorController.textColor.value.withOpacity(0.7),
                      fontSize: _fontSize,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Slider(
                value: _fontSize,
                min: 12,
                max: 40,
                activeColor: colorController.primaryColor.value,
                inactiveColor:
                    colorController.primaryColor.value.withOpacity(0.3),
                onChanged: (double value) {
                  setState(() {
                    _fontSize = value;
                    _countFontSize =
                        value * (_baseCountFontSize / _baseFontSize);
                  });
                },
                onChangeEnd: (double value) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setDouble('fontSize', value);
                  setState(() {
                    _showSlider = false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(ColorController colorController) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Neumorphic(
            style: NeumorphicStyle(
              depth: 4,
              intensity: 0.8,
              color: colorController.backgroundColor.value,
              boxShape: NeumorphicBoxShape.circle(),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: CircularProgressIndicator(
                color: colorController.primaryColor.value,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Obx(() => Text(
                bibleController.loadingMessage.value,
                style: TextStyle(
                  color: colorController.textColor.value,
                  fontSize: _fontSize,
                ),
              )),
        ],
      ),
    );
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

  void _saveHighlight() async {
    // Implementation for saving highlights
    // This would integrate with the existing highlight functionality
  }

  void _shareSelectedVerses() {
    // Implementation for sharing selected verses
    // This would integrate with existing share functionality
  }

  void _updateSearchContext() {
    final selectedBook = bibleController.selectedBook.value;
    final selectedChapter = bibleController.selectedChapter.value;

    if (selectedBook.isEmpty) {
      _currentSearchContext = BibleSearchContext.books;
    } else if (selectedChapter == 0) {
      _currentSearchContext = BibleSearchContext.books;
    } else {
      _currentSearchContext = BibleSearchContext.currentChapter;
    }

    bibleController.setSearchContext(_currentSearchContext);
  }

  Widget _buildSearchResultsView(ColorController colorController) {
    return Column(
      children: [
        _buildNeumorphicSearchBar(colorController),
        Expanded(
          child: Obx(() {
            if (bibleController.isSearching.value) {
              return _buildLoadingWidget(colorController);
            }

            if (bibleController.searchResults.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: colorController.textColor.value.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tsy misy valiny',
                      style: TextStyle(
                        color: colorController.textColor.value.withOpacity(0.7),
                        fontSize: _fontSize,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bibleController.searchResults.length,
              itemBuilder: (context, index) {
                final result = bibleController.searchResults[index];
                return _buildSearchResultItem(result, colorController);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(
      BibleSearchResult result, ColorController colorController) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: NeumorphicButton(
        style: NeumorphicStyle(
          depth: 2,
          intensity: 0.8,
          color: colorController.backgroundColor.value,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        ),
        padding: const EdgeInsets.all(16),
        onPressed: () => bibleController.navigateToSearchResult(result),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.type == BibleSearchResultType.book
                      ? Icons.book
                      : Icons.article,
                  color: colorController.primaryColor.value,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.displayText,
                    style: TextStyle(
                      color: colorController.primaryColor.value,
                      fontSize: _fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (result.type == BibleSearchResultType.verse)
              _buildHighlightedVerseText(result, colorController)
            else
              Text(
                result.subtitle,
                style: TextStyle(
                  color: colorController.textColor.value.withOpacity(0.7),
                  fontSize: _fontSize * 0.9,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedVerseText(
      BibleSearchResult result, ColorController colorController) {
    final query = bibleController.searchQuery.value;
    if (query.isEmpty) {
      return Text(
        result.text,
        style: TextStyle(
          color: colorController.textColor.value.withOpacity(0.7),
          fontSize: _fontSize * 0.9,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    final List<TextSpan> spans = [];
    final lowerText = result.text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(
          text: result.text.substring(start, index),
          style: TextStyle(
            color: colorController.textColor.value.withOpacity(0.7),
            fontSize: _fontSize * 0.9,
          ),
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: result.text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: colorController.primaryColor.value.withOpacity(0.3),
          color: colorController.primaryColor.value,
          fontSize: _fontSize * 0.9,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // Add remaining text
    if (start < result.text.length) {
      spans.add(TextSpan(
        text: result.text.substring(start),
        style: TextStyle(
          color: colorController.textColor.value.withOpacity(0.7),
          fontSize: _fontSize * 0.9,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
