import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/audio_service.dart';

class NowPlayingButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;
  final Color iconColor;
  final Color backgroundColor;

  const NowPlayingButtonWidget({
    super.key,
    required this.onPressed,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final audioService = AudioService.instance;
      final currentHymnId = audioService.currentPlayingHymnId;
      final isPlaying = currentHymnId.isNotEmpty && audioService.isPlaying;

      return IconButton(
        key: const ValueKey('now_playing_button'),
        icon: Stack(
          children: [
            Icon(
              Icons.play_circle,
              color: isPlaying
                  ? Theme.of(context).colorScheme.primary
                  : iconColor,
            ),
            if (isPlaying)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: backgroundColor,
                      width: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        onPressed: onPressed,
      );
    });
  }
}