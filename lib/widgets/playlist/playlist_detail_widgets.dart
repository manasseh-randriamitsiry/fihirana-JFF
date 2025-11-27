import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controller/color_controller.dart';
import '../../models/hymn.dart';
import '../../l10n/app_localizations.dart';

class PlaylistHymnItem extends StatelessWidget {
  final Hymn hymn;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const PlaylistHymnItem({
    super.key,
    required this.hymn,
    required this.index,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return Card(
      color: colorController.backgroundColor.value,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorController.textColor.value.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: colorController.primaryColor.value,
          child: Text(
            hymn.number.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          hymn.title,
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          color: Colors.red.withValues(alpha: 0.7),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

class PlaylistHeaderInfo extends StatelessWidget {
  final DateTime date;
  final int hymnCount;
  final ValueChanged<DateTime> onDateChanged;

  const PlaylistHeaderInfo({
    super.key,
    required this.date,
    required this.hymnCount,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      color: colorController.primaryColor.value.withValues(alpha: 0.05),
      child: Row(
        children: [
          Icon(Icons.calendar_today,
              size: 16, color: colorController.primaryColor.value),
          const SizedBox(width: 8),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2000),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: colorController.primaryColor.value,
                        onPrimary: Colors.white,
                        surface: colorController.backgroundColor.value,
                        onSurface: colorController.textColor.value,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                onDateChanged(picked);
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(date),
                    style: TextStyle(
                      color: colorController.textColor.value,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.dotted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit,
                    size: 14,
                    color: colorController.textColor.value.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            l10n.hymnsCount(hymnCount),
            style: TextStyle(
              color: colorController.textColor.value.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}