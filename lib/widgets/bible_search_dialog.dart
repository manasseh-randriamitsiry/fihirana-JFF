import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:get/get.dart';
import '../controller/bible_controller.dart';
import '../controller/color_controller.dart';
import '../models/bible_search.dart';

class BibleSearchDialog extends StatefulWidget {
  const BibleSearchDialog({super.key});

  @override
  State<BibleSearchDialog> createState() => _BibleSearchDialogState();
}

class _BibleSearchDialogState extends State<BibleSearchDialog> {
  final BibleController bibleController = Get.find<BibleController>();
  final ColorController colorController = Get.find<ColorController>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  BibleSearchContext _currentSearchContext = BibleSearchContext.books;
  final double _fontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _initializeSearch();
  }

  void _initializeSearch() {
    // Set initial search context based on current state
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
    
    // Request focus after dialog is fully shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _searchFocusNode.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.85,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: Neumorphic(
          style: NeumorphicStyle(
            depth: 6,
            intensity: 0.8,
            color: colorController.backgroundColor.value,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildSearchContextSelector(),
              Expanded(child: _buildSearchResults()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorController.primaryColor.value.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: colorController.primaryColor.value,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Karoka Baiboly',
              style: TextStyle(
                color: colorController.primaryColor.value,
                fontSize: _fontSize * 1.3,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          NeumorphicButton(
            style: NeumorphicStyle(
              depth: 2,
              color: colorController.backgroundColor.value,
              boxShape: NeumorphicBoxShape.circle(),
            ),
            child: Icon(
              Icons.close,
              color: colorController.iconColor.value,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 3,
          intensity: 0.8,
          color: colorController.backgroundColor.value,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: TextStyle(
            color: colorController.textColor.value,
            fontSize: _fontSize,
          ),
          decoration: InputDecoration(
            hintText: 'Karoka teny na andininy...',
            hintStyle: TextStyle(
              color: colorController.textColor.value.withOpacity(0.6),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: colorController.iconColor.value,
            ),
            suffixIcon: Obx(() {
              if (bibleController.searchQuery.value.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: NeumorphicButton(
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
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) {
            bibleController.performSearch(value);
          },
          onSubmitted: (value) {
            // Handle search submission if needed
          },
        ),
      ),
    );
  }

  Widget _buildSearchContextSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Neumorphic(
        style: NeumorphicStyle(
          depth: 2,
          intensity: 0.6,
          color: colorController.backgroundColor.value,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildContextButton(
                context: BibleSearchContext.books,
                icon: Icons.book,
                label: 'Boky',
              ),
            ),
            Expanded(
              child: _buildContextButton(
                context: BibleSearchContext.currentChapter,
                icon: Icons.article,
                label: 'Toko misy anko',
              ),
            ),
            Expanded(
              child: _buildContextButton(
                context: BibleSearchContext.allBible,
                icon: Icons.menu_book,
                label: 'Baiboly manontolo',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextButton({
    required BibleSearchContext context,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentSearchContext == context;
    
    return NeumorphicButton(
      style: NeumorphicStyle(
        depth: isSelected ? 1 : 2,
        color: isSelected
            ? colorController.primaryColor.value
            : colorController.backgroundColor.value,
        boxShape: const NeumorphicBoxShape.stadium(),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      onPressed: () {
        setState(() {
          _currentSearchContext = context;
          bibleController.setSearchContext(context);
          // Re-run search with new context
          bibleController.performSearch(_searchController.text);
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? Colors.white
                : colorController.textColor.value,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : colorController.textColor.value,
              fontSize: _fontSize * 0.8,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Obx(() {
        if (bibleController.isSearching.value) {
          return _buildLoadingWidget();
        }

        if (bibleController.searchQuery.value.isEmpty) {
          return _buildEmptySearchWidget();
        }

        if (bibleController.searchResults.isEmpty) {
          return _buildNoResultsWidget();
        }

        return _buildResultsList();
      }),
    );
  }

  Widget _buildLoadingWidget() {
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
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Mikaroka...',
            style: TextStyle(
              color: colorController.textColor.value.withOpacity(0.7),
              fontSize: _fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: colorController.textColor.value.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Soraty ny teny hikarohana',
            style: TextStyle(
              color: colorController.textColor.value.withOpacity(0.5),
              fontSize: _fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsWidget() {
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
            'Tsy misy valin\'ny karoka',
            style: TextStyle(
              color: colorController.textColor.value.withOpacity(0.7),
              fontSize: _fontSize,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mandeha manova ny teny karoka',
            style: TextStyle(
              color: colorController.textColor.value.withOpacity(0.5),
              fontSize: _fontSize * 0.9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: bibleController.searchResults.length,
      itemBuilder: (context, index) {
        final result = bibleController.searchResults[index];
        return _buildSearchResultItem(result);
      },
    );
  }

  Widget _buildSearchResultItem(BibleSearchResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: NeumorphicButton(
        style: NeumorphicStyle(
          depth: 2,
          intensity: 0.8,
          color: colorController.backgroundColor.value,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(12)),
        ),
        padding: const EdgeInsets.all(16),
        onPressed: () {
          Navigator.of(context).pop(); // Close dialog first
          bibleController.navigateToSearchResult(result);
        },
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
                  size: 18,
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
              _buildHighlightedVerseText(result)
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

  Widget _buildHighlightedVerseText(BibleSearchResult result) {
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