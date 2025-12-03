import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/features/bible/presentation/controllers/bible_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/bible/domain/entities/bible_search.dart';
import 'bible_search_header.dart';
import 'bible_search_input.dart';
import 'bible_search_context_selector.dart';
import 'bible_search_results.dart';

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
            const BibleSearchHeader(),
            BibleSearchInput(
              controller: _searchController,
              focusNode: _searchFocusNode,
              fontSize: _fontSize,
            ),
            BibleSearchContextSelector(
              currentContext: _currentSearchContext,
              onContextChanged: (context) {
                setState(() {
                  _currentSearchContext = context;
                  bibleController.setSearchContext(context);
                  bibleController.performSearch(_searchController.text);
                });
              },
            ),
            Expanded(
              child: BibleSearchResults(fontSize: _fontSize),
            ),
          ],
        ),
      ),
    );
  }












}
