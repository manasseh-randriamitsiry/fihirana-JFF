import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';
import 'package:fihirana/features/audio/data/services/audio_service.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';
import 'package:fihirana/shared/widgets/common/app_card.dart';

class FavoriteHymnCard extends StatelessWidget {
  final Hymn hymn;
  final bool hasAudio;
  final bool isPlaying;
  final bool isFavorite;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onAudioPressed;
  final VoidCallback onFavoritePressed;

  const FavoriteHymnCard({
    super.key,
    required this.hymn,
    required this.hasAudio,
    required this.isPlaying,
    required this.isFavorite,
    required this.index,
    required this.onTap,
    required this.onAudioPressed,
    required this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final audioService = AudioService.instance;
    final backgroundColor = colorController.backgroundColor.value;
    final primaryColor = colorController.primaryColor.value;
    final textColor = colorController.textColor.value;

    // Pastel color like hymn list item
    final pastelColor = Color.alphaBlend(
      primaryColor.withValues(alpha: 0.05),
      backgroundColor,
    );

    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AppCard(
        backgroundColor: pastelColor,
        borderRadius: AppDimensions.radiusXxl,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hymn Number Badge
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                hymn.hymnNumber,
                style: textTheme.titleMedium?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Title and Preview
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hymn.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (hymn.verses.isNotEmpty)
                    Text(
                      hymn.verses[0],
                      style: textTheme.bodyMedium?.copyWith(
                        color: textColor.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Audio button
                if (hasAudio)
                  Obx(() {
                    final isCurrentlyPlaying = audioService.isHymnPlaying(hymn.id);
                    return IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        onAudioPressed();
                      },
                      icon: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCurrentlyPlaying
                              ? primaryColor.withValues(alpha: 0.1)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCurrentlyPlaying ? Icons.graphic_eq : Icons.music_note_outlined,
                          size: 20,
                          color: isCurrentlyPlaying
                              ? primaryColor
                              : textColor.withValues(alpha: 0.6),
                        ),
                      ),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(40, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    );
                  }),

                // Favorite button
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onFavoritePressed();
                  },
                  icon: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? Colors.redAccent : textColor.withValues(alpha: 0.6),
                    size: 22,
                  ),
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: (50 * index).ms).slideY(
        begin: 0.1,
        end: 0,
        duration: 300.ms,
        delay: (50 * index).ms,
        curve: Curves.easeOut);
  }
}
