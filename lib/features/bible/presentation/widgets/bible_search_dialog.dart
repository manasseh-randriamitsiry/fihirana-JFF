import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/features/bible/presentation/controllers/bible_search_controller.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
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
  final BibleSearchController search = Get.find<BibleSearchController>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // The search state lives with the reader, which outlives this dialog.
    // Without the reset a reopened dialog shows an empty field above the hits
    // of the search that was closed.
    search.resetSearch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
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
    final s = AppSurfaces.of(context);
    // The keyboard has to move the sheet, or it covers the field being typed
    // into and the results below it.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Dialog(
      backgroundColor: s.sheet,
      elevation: 0,
      insetPadding: EdgeInsets.fromLTRB(AppScale.space16, AppScale.space16,
          AppScale.space16, AppScale.space16 + keyboard),
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(AppScale.radiusSheet))),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            const BibleSearchHeader(),
            BibleSearchInput(
              controller: _searchController,
              focusNode: _searchFocusNode,
            ),
            const BibleSearchContextSelector(),
            const Expanded(child: BibleSearchResults()),
          ],
        ),
      ),
    );
  }
}
