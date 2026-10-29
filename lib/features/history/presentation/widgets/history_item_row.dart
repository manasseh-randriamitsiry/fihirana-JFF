import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/components/app_register_row.dart';
import 'package:fihirana/l10n/app_localizations.dart';

/// A line of the reader's own register: the hymn they opened, and when.
class HistoryItemRow extends StatelessWidget {
  final Map<String, dynamic> history;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool?>? onSelectionChanged;

  const HistoryItemRow({
    super.key,
    required this.history,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Object number = history['number'] ?? '';
    final int? numberValue = int.tryParse('$number');
    final String title = history['title'] ??
        (numberValue == null ? l10n.hymns : l10n.hymnNumber(numberValue));

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.lightImpact();
        onLongPress();
      },
      child: AppRegisterRow(
        figure: '$number',
        title: title,
        subtitle: _relativeTime(
            DateTime.tryParse('${history['timestamp']}') ?? DateTime.now(),
            l10n),
        selected: isSelected,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        trailing: isSelectionMode
            ? Padding(
                padding: const EdgeInsets.only(right: AppScale.space12),
                child: Checkbox(
                  value: isSelected,
                  onChanged: onSelectionChanged,
                ),
              )
            : Icon(Icons.chevron_right_rounded,
                color: s.muted, size: AppScale.iconLg),
      ),
    );
  }

  String _relativeTime(DateTime at, AppLocalizations l10n) {
    final difference = DateTime.now().difference(at);
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) return l10n.justNow;
        return l10n.minutesAgo(difference.inMinutes);
      }
      return l10n.hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.daysAgo(difference.inDays);
    }
    return '${at.day}/${at.month}/${at.year}';
  }
}
