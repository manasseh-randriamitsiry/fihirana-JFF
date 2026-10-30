import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/design_system/app_scale.dart';

class BibleSearchHeader extends StatelessWidget {
  const BibleSearchHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorController = Get.find<ColorController>();

    return Container(
      padding: const EdgeInsets.all(AppScale.gutter),
      decoration: BoxDecoration(
        color: colorController.primaryColor.value.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppScale.radiusFloat),
          topRight: Radius.circular(AppScale.radiusFloat),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: colorController.primaryColor.value,
            size: 28,
          ),
          const SizedBox(width: AppScale.space12),
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
