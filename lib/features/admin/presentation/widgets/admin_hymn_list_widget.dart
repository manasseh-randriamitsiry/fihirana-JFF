import 'package:flutter/material.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/skeleton_admin_list.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/features/admin/presentation/widgets/admin_hymn_widgets.dart';

class AdminHymnListWidget extends StatelessWidget {
  final List<String> selectedHymns;
  final Function(String) onSelectionChanged;

  const AdminHymnListWidget({
    super.key,
    required this.selectedHymns,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<List<Hymn>>(
      stream: HymnService().getFirebaseHymnsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${l10n.error}: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonAdminList();
        }

        final hymns = snapshot.data ?? [];
        hymns.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (hymns.isEmpty) {
          return const AdminEmptyHymnsWidget();
        }

        return ListView.builder(
          key: const PageStorageKey('admin_hymns_list'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: hymns.length,
          itemBuilder: (context, index) {
            final hymn = hymns[index];
            final isSelected = selectedHymns.contains(hymn.id);

            return AdminHymnListItemWidget(
              key: ValueKey(hymn.id),
              hymn: hymn,
              isSelected: isSelected,
              onSelectionChanged: (_) => onSelectionChanged(hymn.id),
            );
          },
        );
      },
    );
  }
}
