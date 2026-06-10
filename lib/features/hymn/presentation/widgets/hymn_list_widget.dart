import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/hymn/presentation/controllers/hymn_controller.dart';
import 'hymn_list_item.dart';
import 'package:fihirana/shared/widgets/common/empty_state_widget.dart';
import 'package:fihirana/shared/widgets/common/skeleton_hymn_list.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/features/audio/presentation/pages/audio_player_screen.dart';

class HymnListWidget extends StatelessWidget {
  final HymnController hymnController;
  final TextStyle defaultTextStyle;
  final Color textColor;
  final Color backgroundColor;
  final List<Hymn>? playlist;
  final int? initialIndex;

  const HymnListWidget({
    super.key,
    required this.hymnController,
    required this.defaultTextStyle,
    required this.textColor,
    required this.backgroundColor,
    this.playlist,
    this.initialIndex,
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
                AppLocalizations.of(context)
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
              message: AppLocalizations.of(context).noHymnsFound,
              icon: Icons.music_off_rounded,
              actionLabel: AppLocalizations.of(context).clearSearch,
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
            final colorController = Get.find<ColorController>();
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final hymn = hymns[index];
                  final isFavorite =
                      favoriteSnapshot.data?[hymn.id]?.isNotEmpty ?? false;
                  return HymnListItem(
                    key: ValueKey(hymn.id),
                    hymn: hymn,
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                    primaryColor: colorController.primaryColor.value,
                    isFavorite: isFavorite,
                    onFavoritePressed: () =>
                        hymnController.toggleFavorite(hymn),
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
    // Navigate to enhanced audio player with flexible options
    AudioPlayerNavigator.navigateToEnhancedPlayer(
      Get.context!,
      hymn: hymn,
      playlist: playlist, // Use provided playlist if available
      initialIndex: initialIndex, // Use provided initial index if available
    );
  }
}
