import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/bible_controller.dart';
import '../controller/color_controller.dart';
import '../models/bible_search.dart';
import '../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          color: colorController.backgroundColor.value,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(l10n),
            _buildSearchContextSelector(l10n),
            Expanded(child: _buildSearchResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorController.primaryColor.value.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: colorController.primaryColor.value,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.searchBible,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: colorController.textColor.value,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded,
                color: colorController.iconColor.value),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorController.primaryColor.value.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorController.primaryColor.value.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: TextStyle(
          fontFamily: 'Roboto',
          color: colorController.textColor.value,
          fontSize: _fontSize,
        ),
        decoration: InputDecoration(
          hintText: l10n.searchWordsOrVersesHint,
          hintStyle: TextStyle(
            fontFamily: 'Roboto',
            color: colorController.textColor.value.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colorController.iconColor.value,
          ),
          suffixIcon: Obx(() {
            if (bibleController.searchQuery.value.isNotEmpty) {
              return IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: colorController.iconColor.value,
                ),
                onPressed: () {
                  _searchController.clear();
                  bibleController.performSearch('');
                },
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
      ),
    );
  }

  Widget _buildSearchContextSelector(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildContextButton(
              context: BibleSearchContext.books,
              icon: Icons.book_rounded,
              label: l10n.searchBooks,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildContextButton(
              context: BibleSearchContext.allBible,
              icon: Icons.menu_book_rounded,
              label: l10n.wholeBible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextButton({
    required BibleSearchContext context,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentSearchContext == context;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentSearchContext = context;
          bibleController.setSearchContext(context);
          bibleController.performSearch(_searchController.text);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorController.primaryColor.value
              : colorController.primaryColor.value.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorController.primaryColor.value
                : colorController.primaryColor.value.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color:
                  isSelected ? Colors.white : colorController.textColor.value,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: isSelected
                      ? Colors.white
                      : colorController.textColor.value,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colorController.primaryColor.value,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.search,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: colorController.textColor.value.withValues(alpha: 0.7),
              fontSize: _fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchWidget() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_rounded,
            size: 64,
            color: colorController.textColor.value.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.enterWordToSearch,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: colorController.textColor.value.withValues(alpha: 0.5),
              fontSize: _fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: colorController.textColor.value.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noSearchResults,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: colorController.textColor.value.withValues(alpha: 0.7),
              fontSize: _fontSize,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.changeWordToSearch,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: colorController.textColor.value.withValues(alpha: 0.5),
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
      decoration: BoxDecoration(
        color: colorController.primaryColor.value.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorController.primaryColor.value.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          bibleController.navigateToSearchResult(result,
              highlightVerse: result.verse);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    result.type == BibleSearchResultType.book
                        ? Icons.book_rounded
                        : Icons.article_rounded,
                    color: colorController.primaryColor.value,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.displayText,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: colorController.primaryColor.value,
                        fontSize: _fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
                    fontFamily: 'Roboto',
                    color:
                        colorController.textColor.value.withValues(alpha: 0.7),
                    fontSize: _fontSize * 0.9,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
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
          fontFamily: 'Roboto',
          color: colorController.textColor.value.withValues(alpha: 0.7),
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
            fontFamily: 'Roboto',
            color: colorController.textColor.value.withValues(alpha: 0.7),
            fontSize: _fontSize * 0.9,
          ),
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: result.text.substring(index, index + query.length),
        style: TextStyle(
          fontFamily: 'Roboto',
          backgroundColor:
              colorController.primaryColor.value.withValues(alpha: 0.3),
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
          fontFamily: 'Roboto',
          color: colorController.textColor.value.withValues(alpha: 0.7),
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
