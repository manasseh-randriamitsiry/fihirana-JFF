import 'package:flutter/material.dart';
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
    return Obx(
      () {
        if (hymnController.isLoading.value) {
          return const SliverFillRemaining(
            child: SkeletonHymnList(),
          );
        }

        final hymns = hymnController.filteredHymns;
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

        final colorController = Get.find<ColorController>();
        final primaryColor = colorController.primaryColor.value;
        final favoriteStatuses = hymnController.favoriteStatuses;

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final hymn = hymns[index];
              final isFavorite = favoriteStatuses[hymn.id]?.isNotEmpty ?? false;
              return HymnListItem(
                key: ValueKey(hymn.id),
                hymn: hymn,
                textColor: textColor,
                backgroundColor: backgroundColor,
                primaryColor: primaryColor,
                isFavorite: isFavorite,
                onFavoritePressed: () => hymnController.toggleFavorite(hymn),
                onMusicPressed: () => _showAudioPlayerDialog(hymn),
              );
            },
            childCount: hymns.length,
          ),
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
