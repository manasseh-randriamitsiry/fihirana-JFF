import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controller/hymn_controller.dart';
import 'hymn_list_item.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/skeleton_hymn_list.dart';
import '../../models/hymn.dart';
import '../../l10n/app_localizations.dart';

class HymnListWidget extends StatelessWidget {
  final HymnController hymnController;
  final TextStyle defaultTextStyle;
  final Color textColor;
  final Color backgroundColor;

  const HymnListWidget({
    super.key,
    required this.hymnController,
    required this.defaultTextStyle,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Hymn>>(
      stream: hymnController.hymnsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                AppLocalizations.of(context)!
                    .errorOccurredWithDetails(snapshot.error.toString()),
                style: defaultTextStyle,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: SkeletonHymnList(),
          );
        }

        final hymns = hymnController.filterHymnList(snapshot.data ?? []);
        if (hymns.isEmpty) {
          return SliverFillRemaining(
            child: EmptyStateWidget(
              message: AppLocalizations.of(context)!.noHymnsFound,
              icon: Icons.music_off_rounded,
              actionLabel: AppLocalizations.of(context)!.clearSearch,
              onActionPressed: () {
                if (!hymnController.isDisposed) {
                  hymnController.safeSearchController.clear();
                }
              },
            ),
          );
        }

        return StreamBuilder<Map<String, String>>(
          stream: hymnController.getFavoriteStatusStream(),
          builder: (context, favoriteSnapshot) {
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final hymn = hymns[index];
                  return HymnListItem(
                    key: ValueKey(hymn.id),
                    hymn: hymn,
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    onFavoritePressed: () => hymnController.toggleFavorite(hymn),
                    onMusicPressed: () => _showAudioPlayerDialog(hymn),
                  )
                      .animate()
                      .fadeIn(
                          duration: 400.ms,
                          delay: (50 * index).clamp(0, 500).ms)
                      .slideY(
                          begin: 0.2,
                          end: 0,
                          curve: Curves.easeOutQuad,
                          duration: 400.ms);
                },
                childCount: hymns.length,
              ),
            );
          },
        );
      },
    );
  }

  void _showAudioPlayerDialog(Hymn hymn) {
    // This method should be provided by the parent screen
    // For now, we'll use a navigation utility
    // TODO: Make this more flexible
  }
}