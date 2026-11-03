import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_search_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/design_system/app_scale.dart';

/// The keystrokes are the search, so the field waits for a pause rather than a
/// submit. The scan runs on the UI isolate, so the pause also keeps typing
/// responsive.
const Duration _kDebounce = Duration(milliseconds: 250);

class BibleSearchInput extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const BibleSearchInput({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  State<BibleSearchInput> createState() => _BibleSearchInputState();
}

class _BibleSearchInputState extends State<BibleSearchInput> {
  Timer? _debounceTimer;

  BibleSearchController get _searchController =>
      Get.find<BibleSearchController>();

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _search(String value) {
    _debounceTimer?.cancel();
    // updateSearchQuery clears the results when the field is emptied; assigning
    // the query alone left the previous hits on screen under a blank field.
    _searchController.updateSearchQuery(value);
    if (value.trim().isEmpty) return;
    _debounceTimer = Timer(_kDebounce, () {
      if (mounted) _searchController.performSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppScale.gutter, AppScale.space12, AppScale.gutter, AppScale.space4),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        style: type.bodyMedium,
        maxLines: 1,
        textInputAction: TextInputAction.search,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: l10n.searchWordsOrVersesHint,
          prefixIcon: const Icon(Icons.search_rounded, size: AppScale.iconMd),
          suffixIcon: Obx(() {
            if (_searchController.searchQuery.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: const Icon(Icons.clear_rounded, size: AppScale.iconSm),
              tooltip: l10n.clear,
              onPressed: () {
                _debounceTimer?.cancel();
                widget.controller.clear();
                _search('');
              },
            );
          }),
        ),
        onChanged: _search,
        onSubmitted: (_) {
          _debounceTimer?.cancel();
          _searchController.performSearch();
        },
      ),
    );
  }
}
