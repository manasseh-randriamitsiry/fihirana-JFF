import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class BibleSearchHeader extends StatelessWidget {
  const BibleSearchHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorController = Get.find<ColorController>();

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
}