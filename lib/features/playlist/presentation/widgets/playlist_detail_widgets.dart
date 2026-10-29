import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/components/app_register_row.dart';

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
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppScale.buttonGap),
      child: AppRegisterRow(
        figure: hymn.number.toString(),
        title: hymn.title,
        onTap: onTap,
        trailing: IconButton(
          tooltip: AppLocalizations.of(context).delete,
          icon: Icon(
            Icons.remove_circle_outline_rounded,
            color: colors.error,
            size: AppScale.iconLg,
          ),
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
    final AppSurfaces s = AppSurfaces.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMMEEEEd(locale);

    return AppRegisterRow(
      title: dateFormat.format(date),
      subtitle: l10n.hymnsCount(hymnCount),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onDateChanged(picked);
      },
      leadingWidget: Icon(
        Icons.calendar_today_outlined,
        color: s.ink,
        size: AppScale.iconLg,
      ),
      trailing: Icon(Icons.edit_outlined,
          color: s.muted, size: AppScale.iconLg),
    );
  }
}
