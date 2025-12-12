import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class HymnHintSection extends StatelessWidget {
  final Hymn hymn;
  final double fontSize;
  final bool showHint;
  final bool isUserAuthenticated;

  const HymnHintSection({
    super.key,
    required this.hymn,
    required this.fontSize,
    required this.showHint,
    required this.isUserAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorController = Get.find<ColorController>();

    if (!showHint || !(hymn.hymnHint?.trim().toLowerCase().isNotEmpty ?? false)) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (isUserAuthenticated)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorController.primaryColor.value.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.createdBy}: ${hymn.createdBy}',
                  style: TextStyle(
                    fontSize: fontSize * 0.8,
                    color: colorController.textColor.value,
                  ),
                ),
                if (hymn.createdByEmail != null)
                  Text(
                    l10n.emailLabel(hymn.createdByEmail!),
                    style: TextStyle(
                      fontSize: fontSize * 0.8,
                      color: colorController.textColor.value,
                    ),
                  ),
                Text(
                  '${l10n.date}: ${DateTime.fromMillisecondsSinceEpoch(hymn.createdAt.millisecondsSinceEpoch).toString().substring(0, 19)}',
                  style: TextStyle(
                    fontSize: fontSize * 0.8,
                    color: colorController.textColor.value,
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            hymn.hymnHint ?? '',
            style: TextStyle(
              fontSize: 2 * fontSize / 3,
              color: colorController.textColor.value,
            ),
          ),
        ),
      ],
    );
  }
}