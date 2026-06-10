import 'package:flutter/material.dart';
// ignore_for_file: undefined_getter, argument_type_not_assignable, return_of_invalid_type_from_closure, missing_required_argument
import 'package:get/get.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_controller.dart';
import 'package:fihirana/features/bible/di/bible_di.dart';

import 'package:fihirana/app/theme/font_controller.dart';
import 'package:fihirana/features/bible/presentation/widgets/bible_search_dialog.dart';
import 'package:fihirana/features/bible/presentation/widgets/bible_settings_bottom_sheet_widget.dart';

class BibleReaderScreenOptimized extends StatefulWidget {
  const BibleReaderScreenOptimized({super.key});

  @override
  State<BibleReaderScreenOptimized> createState() =>
      _BibleReaderScreenOptimizedState();
}

class _BibleReaderScreenOptimizedState
    extends State<BibleReaderScreenOptimized> {
  late final BibleController bibleController;

  void _initializeBibleController() {
    BibleDI.init();
    bibleController = Get.find<BibleController>();
  }

  final ColorController colorController = Get.find<ColorController>();
  final FontController fontController = Get.find<FontController>();

  // Font settings
  double _fontSize = 18.0;
  String _fontFamily = 'Lato';

  // Scroll controller
  final ScrollController _verseScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeBibleController();
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
    return Scaffold(
      backgroundColor: GetBuilder<ColorController>(
        id: 'background_color',
        builder: (controller) => controller.backgroundColor.value,
      ),
      appBar: _buildAppBar() as PreferredSizeWidget,
      body: Column(
        children: [
          _buildBookChapterSelector(),
          _buildVerseList(),
        ],
      ),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildAppBar() {
    return GetBuilder<BibleController>(
      id: 'app_bar',
      builder: (controller) => AppBar(
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            controller.selectedBook.isEmpty
                ? Icons.menu_rounded
                : Icons.arrow_back_ios_new_rounded,
            color: colorController.iconColor.value,
          ),
          onPressed: () {
            if (controller.selectedBook.isEmpty) {
              Scaffold.of(context).openDrawer();
            } else {
              controller.selectBook('');
            }
          },
        ),
        title: Text(
          controller.selectedBook.isEmpty
              ? context.l10n.bible
              : '${controller.selectedBook} ${controller.selectedChapter}',
          style: TextStyle(
            color: colorController.textColor.value,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          GetBuilder<BibleController>(
            id: 'app_bar_actions',
            builder: (controller) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (controller.selectedBook.isNotEmpty) ...[
                  IconButton(
                    icon: Icon(
                      controller.isSelecting.value
                          ? Icons.close_rounded
                          : Icons.checklist_rounded,
                      color: colorController.iconColor.value,
                    ),
                    onPressed: controller.isSelecting.value
                        ? controller.clearVerseSelection
                        : controller.startVerseSelection,
                  ),
                  if (controller.isSelecting.value &&
                      controller.selectedVerses.isNotEmpty) ...[
                    IconButton(
                      icon: Icon(
                        Icons.highlight_rounded,
                        color: colorController.iconColor.value,
                      ),
                      onPressed: () => _showHighlightOptions(context),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.share_rounded,
                        color: colorController.iconColor.value,
                      ),
                      onPressed: () => _shareSelectedVerses(context),
                    ),
                  ],
                ],
                IconButton(
                  icon: Icon(
                    Icons.search_rounded,
                    color: colorController.iconColor.value,
                  ),
                  onPressed: () => _showSearchDialog(context),
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: colorController.iconColor.value,
                  ),
                  onPressed: () => _showSettingsBottomSheet(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookChapterSelector() {
    return GetBuilder<BibleController>(
      id: 'book_chapter_selector',
      builder: (controller) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorController.cardColor.value,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedBook.isEmpty
                      ? null
                      : controller.selectedBook,
                  hint: Text(
                    context.l10n.selectBook,
                    style: TextStyle(
                      color: colorController.textColor.value,
                    ),
                  ),
                  isExpanded: true,
                  items: controller.bookList.map((book) {
                    return DropdownMenuItem<String>(
                      value: book,
                      child: Text(
                        book,
                        style: TextStyle(
                          color: colorController.textColor.value,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? book) {
                    if (book != null) {
                      controller.selectBook(book);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: controller.selectedChapter.value == 0
                      ? null
                      : controller.selectedChapter.value,
                  hint: Text(
                    context.l10n.selectChapter,
                    style: TextStyle(
                      color: colorController.textColor.value,
                    ),
                  ),
                  isExpanded: true,
                  items: controller.chapterList.map((chapter) {
                    return DropdownMenuItem<int>(
                      value: chapter,
                      child: Text(
                        chapter.toString(),
                        style: TextStyle(
                          color: colorController.textColor.value,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (int? chapter) {
                    if (chapter != null) {
                      controller.selectChapter(chapter);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseList() {
    return GetBuilder<BibleController>(
      id: 'verse_list',
      builder: (controller) => Expanded(
        child: controller.isLoading.value
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorController.primaryColor.value,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.loadingMessage.value,
                      style: TextStyle(
                        color: colorController.textColor.value,
                      ),
                    ),
                  ],
                ),
              )
            : controller.passageText.value.isEmpty
                ? Center(
                    child: Text(
                      context.l10n.selectBookChapter,
                      style: TextStyle(
                        color: colorController.textColor.value,
                        fontSize: 16,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    controller: _verseScrollController,
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      controller.passageText.value,
                      style: _verseStyle,
                    ),
                  ),
      ),
    );
  }

  Widget _buildFloatingActions() {
    return GetBuilder<BibleController>(
      id: 'floating_actions',
      builder: (controller) => controller.selectedBook.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FloatingActionButton(
                    mini: true,
                    heroTag: "decrease_font",
                    onPressed: () {
                      setState(() {
                        if (_fontSize > 12) {
                          _fontSize -= 2;
                          _saveSettings();
                        }
                      });
                    },
                    child: Icon(
                      Icons.text_decrease,
                      color: colorController.iconColor.value,
                    ),
                  ),
                  FloatingActionButton(
                    mini: true,
                    heroTag: "increase_font",
                    onPressed: () {
                      setState(() {
                        if (_fontSize < 32) {
                          _fontSize += 2;
                          _saveSettings();
                        }
                      });
                    },
                    child: Icon(
                      Icons.text_increase,
                      color: colorController.iconColor.value,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BibleSearchDialog(),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const BibleSettingsBottomSheetWidget(),
    );
  }

  void _showHighlightOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Highlight Color',
              style: TextStyle(
                color: colorController.textColor.value,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildColorOption(Colors.yellow),
                _buildColorOption(Colors.green),
                _buildColorOption(Colors.blue),
                _buildColorOption(Colors.pink),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () {
        // Add highlight with selected color
        Navigator.pop(context);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: colorController.textColor.value.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  void _shareSelectedVerses(BuildContext context) {
    // Implement sharing functionality
  }
}
