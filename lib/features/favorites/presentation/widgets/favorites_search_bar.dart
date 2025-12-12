import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';

class FavoritesSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const FavoritesSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
  });

  @override
  State<FavoritesSearchBar> createState() => _FavoritesSearchBarState();
}

class _FavoritesSearchBarState extends State<FavoritesSearchBar> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Container(
        decoration: BoxDecoration(
          color: colorController.backgroundColor.value,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorController.textColor.value.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: widget.controller,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
            widget.onChanged(value);
          },
          decoration: InputDecoration(
            hintText: l10n.searchFavoriteSongsHint,
            hintStyle: TextStyle(
              color: colorController.iconColor.value.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: colorController.iconColor.value,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: colorController.iconColor.value,
                    ),
                    onPressed: () {
                      widget.controller.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                      widget.onChanged('');
                      widget.onClear?.call();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: TextStyle(
            color: colorController.textColor.value,
          ),
        ),
      ),
    );
  }
}