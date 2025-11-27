import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../../models/hymn.dart';
import '../../services/audio_service.dart';
import '../../widgets/lightweight_audio_player_widget.dart';
import '../../l10n/app_localizations.dart';

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

  void _showAudioPlayerDialog(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final l10n = AppLocalizations.of(context)!;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: colorController.backgroundColor.value,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.audioPlayer,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorController.textColor.value,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: colorController.iconColor.value,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LightweightAudioPlayerWidget(
                  hymn: hymn,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final audioService = AudioService.instance;
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorController.textColor.value.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      color: colorController.backgroundColor.value,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorController.primaryColor.value.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: colorController.primaryColor.value.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              hymn.hymnNumber,
              style: TextStyle(
                color: colorController.primaryColor.value,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          hymn.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorController.textColor.value,
            fontSize: 16,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Audio button
            if (hasAudio)
              Obx(() {
                final isCurrentlyPlaying = audioService.isHymnPlaying(hymn.id);
                return Container(
                  decoration: BoxDecoration(
                    color: isCurrentlyPlaying
                        ? colorController.primaryColor.value.withValues(alpha: 0.15)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Stack(
                      children: [
                        Icon(
                          Icons.music_note,
                          color: isCurrentlyPlaying
                              ? colorController.primaryColor.value
                              : colorController.iconColor.value,
                          size: 22,
                        ),
                        if (isCurrentlyPlaying)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () => _showAudioPlayerDialog(context),
                    tooltip: l10n.playAudio,
                  ),
                );
              }),
            // Favorite button
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : colorController.iconColor.value,
                size: 24,
              ),
              onPressed: onFavoritePressed,
              tooltip: isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
            ),
          ],
        ),
        onTap: onTap,
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (50 * index).ms)
        .slideY(
            begin: 0.1,
            end: 0,
            duration: 300.ms,
            delay: (50 * index).ms,
            curve: Curves.easeOut);
  }
}