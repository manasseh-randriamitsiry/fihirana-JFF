import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';
import '../common/localization_extension.dart';

class UpdateButtonWidget extends StatelessWidget {
  final bool isDownloading;
  final bool updateAvailable;
  final VoidCallback? onPressed;

  const UpdateButtonWidget({
    super.key,
    required this.isDownloading,
    required this.updateAvailable,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final iconColor = colorController.iconColor.value;

    if (!updateAvailable) {
      return const SizedBox.shrink();
    }

    return IconButton(
      key: const ValueKey('update_button'),
      icon: isDownloading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            )
          : Icon(Icons.system_update, color: iconColor),
      onPressed: onPressed,
      tooltip: context.translate((l) => l.updateAvailable),
    );
  }
}

class NowPlayingButtonWidget extends StatelessWidget {
  final String currentHymnId;
  final bool isPlaying;
  final VoidCallback onPressed;

  const NowPlayingButtonWidget({
    super.key,
    required this.currentHymnId,
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final iconColor = colorController.iconColor.value;

    if (currentHymnId.isEmpty) {
      return IconButton(
        key: const ValueKey('play_first_button'),
        icon: Icon(Icons.play_circle_outline, color: iconColor),
        onPressed: onPressed,
        tooltip: context.translate((l) => l.playFirstHymn),
      );
    }

    return IconButton(
      key: const ValueKey('now_playing_button'),
      icon: isPlaying
          ? Icon(Icons.play_circle_filled, color: iconColor)
          : Icon(Icons.play_circle_outline, color: iconColor),
      onPressed: onPressed,
      tooltip: context.translate((l) => l.nowPlaying),
    );
  }
}