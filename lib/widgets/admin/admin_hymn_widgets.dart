import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/hymn.dart';
import '../../controller/color_controller.dart';
import '../../l10n/app_localizations.dart';

class AdminHymnListItemWidget extends StatelessWidget {
  final Hymn hymn;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final Color primaryColor;

  const AdminHymnListItemWidget({
    super.key,
    required this.hymn,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final textColor = colorController.textColor.value;
    final backgroundColor = colorController.backgroundColor.value;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: backgroundColor,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Checkbox(
            value: isSelected,
            activeColor: primaryColor,
            side: BorderSide(color: textColor.withValues(alpha: 0.5)),
            onChanged: onSelectionChanged,
          ),
          title: Text(
            '${hymn.hymnNumber} - ${hymn.title}',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${l10n.createdBy}: ${hymn.createdBy}',
                style: TextStyle(color: textColor.withValues(alpha: 0.7)),
              ),
              if (hymn.createdByEmail != null)
                Text(
                  l10n.emailLabel(hymn.createdByEmail!),
                  style: TextStyle(
                      color: textColor.withValues(alpha: 0.6),
                      fontSize: 12),
                ),
              Text(
                '${l10n.date}: ${DateFormat('dd/MM/yyyy HH:mm').format(hymn.createdAt)}',
                style: TextStyle(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: 12),
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(
              duration: const Duration(milliseconds: 300))
          .slideY(
              begin: 0.1,
              end: 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut),
    );
  }
}

class AdminEmptyHymnsWidget extends StatelessWidget {
  const AdminEmptyHymnsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final textColor = colorController.textColor.value;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined,
                  size: 64, color: textColor.withValues(alpha: 0.3))
              .animate(
                  onPlay: (controller) =>
                      controller.repeat(reverse: true))
              .scale(
                  duration: const Duration(seconds: 2),
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  curve: Curves.easeInOut),
          const SizedBox(height: 16),
          Text(
            l10n.noHymns,
            style: TextStyle(
                color: textColor.withValues(alpha: 0.7), fontSize: 16),
          ),
        ],
      ),
    );
  }
}