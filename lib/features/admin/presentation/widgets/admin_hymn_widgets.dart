import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

class AdminHymnListItemWidget extends StatelessWidget {
  final Hymn hymn;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;

  const AdminHymnListItemWidget({
    super.key,
    required this.hymn,
    required this.isSelected,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: AppGroupedSurface(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Checkbox(
              value: isSelected,
              onChanged: onSelectionChanged,
            ),
            title: Text(
              '${hymn.hymnNumber} - ${hymn.title}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${l10n.createdBy}: ${hymn.createdBy}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (hymn.createdByEmail != null)
                  Text(
                    l10n.emailLabel(hymn.createdByEmail!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                Text(
                  '${l10n.date}: ${DateFormat('dd/MM/yyyy HH:mm').format(hymn.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ).animate().fadeIn(duration: const Duration(milliseconds: 300)).slideY(
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
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                  duration: const Duration(seconds: 2),
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  curve: Curves.easeInOut),
          const SizedBox(height: 16),
          Text(
            l10n.noHymns,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
