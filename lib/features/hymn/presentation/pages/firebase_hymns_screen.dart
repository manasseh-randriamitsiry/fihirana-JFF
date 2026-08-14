import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/features/hymn/data/services/hymn_service.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/hymn/presentation/widgets/hymn_list_item.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

class FirebaseHymnsScreen extends StatefulWidget {
  const FirebaseHymnsScreen({super.key});

  @override
  State<FirebaseHymnsScreen> createState() => _FirebaseHymnsScreenState();
}

class _FirebaseHymnsScreenState extends State<FirebaseHymnsScreen> {
  final HymnService _hymnService = Get.find<HymnService>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return AppPageScaffold(
      title: l10n.additionalHymns,
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        icon: const Icon(Icons.menu_rounded),
        onPressed: Get.find<ShellController>().toggleDrawer,
      ),
      body: StreamBuilder<List<Hymn>>(
        stream: _hymnService.getFirebaseHymnsStream(),
        builder: (context, hymnSnapshot) {
          if (hymnSnapshot.hasError) {
            return AppEmptyState(
              icon: Icons.cloud_off_rounded,
              title: l10n.unableToLoadAdditionalHymns,
              message: l10n.checkConnectionAndTryAgain,
              action: TextButton(
                  onPressed: () => setState(() {}), child: Text(l10n.tryAgain)),
            );
          }
          if (!hymnSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final hymns = hymnSnapshot.data!;
          if (hymns.isEmpty) {
            return AppEmptyState(
              icon: Icons.library_music_outlined,
              title: l10n.noAdditionalHymns,
              message: l10n.communityHymnsWillAppear,
            );
          }
          return StreamBuilder<Map<String, String>>(
            stream: _hymnService.getFavoriteStatusStream(),
            initialData: _hymnService.currentFavoriteStatus,
            builder: (context, favoriteSnapshot) {
              final favorites =
                  favoriteSnapshot.data ?? const <String, String>{};
              return ListView.separated(
                key: const PageStorageKey('firebase_hymns_list'),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                itemCount: hymns.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final hymn = hymns[index];
                  return HymnListItem(
                    key: ValueKey(hymn.id),
                    hymn: hymn,
                    textColor: colors.onSurface,
                    backgroundColor: colors.surface,
                    primaryColor: colors.primary,
                    onFavoritePressed: () => _hymnService.toggleFavorite(hymn),
                    isFirebaseHymn: true,
                    isFavorite: favorites[hymn.id]?.isNotEmpty ?? false,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
