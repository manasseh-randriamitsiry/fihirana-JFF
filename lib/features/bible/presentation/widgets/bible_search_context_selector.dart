import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_controller.dart';
import 'package:fihirana/features/bible/domain/entities/bible_search.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class BibleSearchContextSelector extends StatefulWidget {
  final BibleSearchContext currentContext;
  final Function(BibleSearchContext) onContextChanged;

  const BibleSearchContextSelector({
    super.key,
    required this.currentContext,
    required this.onContextChanged,
  });

  @override
  State<BibleSearchContextSelector> createState() =>
      _BibleSearchContextSelectorState();
}

class _BibleSearchContextSelectorState
    extends State<BibleSearchContextSelector> {
  final BibleController bibleController = Get.find<BibleController>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildContextButton(
              searchContext: BibleSearchContext.books,
              icon: Icons.book_rounded,
              label: l10n.searchBooks,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildContextButton(
              searchContext: BibleSearchContext.allBible,
              icon: Icons.menu_book_rounded,
              label: l10n.wholeBible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextButton({
    required BibleSearchContext searchContext,
    required IconData icon,
    required String label,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isSelected = widget.currentContext == searchContext;

    return GestureDetector(
      onTap: () {
        widget.onContextChanged(searchContext);
        bibleController.setSearchContext(searchContext);
        // The search will be performed by the parent widget
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? colors.onPrimary : colors.onPrimaryContainer,
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color:
                      isSelected ? colors.onPrimary : colors.onPrimaryContainer,
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
}
