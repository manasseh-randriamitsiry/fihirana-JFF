import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/color_controller.dart';
import '../../controller/bible_controller.dart';
import '../../widgets/color_picker_widget.dart';
import '../../widgets/bible_search_dialog.dart';
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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Font size variables
  final double _baseFontSize = 18.0;
  double _fontSize = 18.0;
  bool _showSlider = false;

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
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    Icons.search,
                    color: colorController.iconColor.value,
                    size: 20,
                  ),
                  onPressed: () {
                    _showSearchDialog();
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

    // If no book selected, show book list
    if (selectedBook.isEmpty) {
      return _buildBookListView(colorController);
    }

    // If book selected but no chapter, show chapter selection
    if (selectedChapter == 0) {
      return _buildChapterSelectionView(colorController);
    }

    // If chapter selected, show verse reading view
    return _buildVerseReadingView(colorController);
  }



  Widget _buildBookListView(ColorController colorController) {
    return Column(
      children: [
        // Font size slider
        if (_showSlider) _buildNeumorphicFontSizeSlider(colorController),

        // Books organized by testament
        Expanded(
          child: Obx(() {
            if (bibleController.isLoading.value) {
              return _buildLoadingWidget(colorController);
            }

            final booksByTestament = bibleController.filteredBooks.isEmpty
                ? bibleController.booksByTestament
                : _getFilteredBooksByTestament();

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: ListView.builder(
                key: ValueKey(booksByTestament.length),
                padding: const EdgeInsets.all(16),
                itemCount: booksByTestament.length,
                itemBuilder: (context, index) {
                  final testamentName = booksByTestament.keys.elementAt(index);
                  final books = booksByTestament[testamentName]!;

                  return _buildTestamentSection(
                    testamentName: testamentName,
                    books: books,
                    colorController: colorController,
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Map<String, List<String>> _getFilteredBooksByTestament() {
    final filteredBooks = bibleController.filteredBooks;
    final allBooksByTestament = bibleController.booksByTestament;
    
    final result = <String, List<String>>{};
    
    for (final testamentName in allBooksByTestament.keys) {
      final testamentBooks = allBooksByTestament[testamentName]!;
      final filteredTestamentBooks = testamentBooks
          .where((book) => filteredBooks.contains(book))
          .toList();
      
      if (filteredTestamentBooks.isNotEmpty) {
        result[testamentName] = filteredTestamentBooks;
      }
    }
    
    return result;
  }

  Widget _buildTestamentSection({
    required String testamentName,
    required List<String> books,
    required ColorController colorController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Testament header
        Container(
          margin: const EdgeInsets.only(bottom: 16),
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
                  Icon(
                    Icons.menu_book,
                    color: colorController.primaryColor.value,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      testamentName,
                      style: TextStyle(
                        color: colorController.primaryColor.value,
                        fontSize: _fontSize * 1.1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorController.primaryColor.value,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${books.length} boky',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Books grid for this testament
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final bookName = books[index];
            final chapterCount = bibleController.getChapterCountForBook(bookName);

            return _buildNeumorphicBookItem(
              bookName: bookName,
              chapterCount: chapterCount,
              colorController: colorController,
              onTap: () => bibleController.selectBook(bookName),
            );
          },
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

  void _showSearchDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const BibleSearchDialog(),
    );
  }

}
