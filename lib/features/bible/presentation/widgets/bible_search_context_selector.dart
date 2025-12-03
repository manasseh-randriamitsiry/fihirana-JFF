import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/bible/presentation/controllers/bible_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
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
  State<BibleSearchContextSelector> createState() => _BibleSearchContextSelectorState();
}

class _BibleSearchContextSelectorState extends State<BibleSearchContextSelector> {
  final BibleController bibleController = Get.find<BibleController>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
    final colorController = Get.find<ColorController>();
    final isSelected = widget.currentContext == context;

    return GestureDetector(
      onTap: () {
        widget.onContextChanged(context);
        bibleController.setSearchContext(context);
        // The search will be performed by the parent widget
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
}