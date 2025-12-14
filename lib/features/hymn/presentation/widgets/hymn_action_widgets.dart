import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';

import 'package:fihirana/shared/widgets/common/localization_extension.dart';

class FontSizeSliderWidget extends StatelessWidget {
  final double fontSize;
  final Function(double) onChanged;
  final Function(double)? onChangeEnd;

  const FontSizeSliderWidget({
    super.key,
    required this.fontSize,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return Slider(
      value: fontSize,
      min: 8,
      max: 50,
      divisions: 56,
      label: fontSize.toStringAsFixed(1),
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      activeColor: colorController.primaryColor.value,
      inactiveColor: colorController.primaryColor.value.withValues(alpha: 0.2),
      thumbColor: colorController.primaryColor.value,
    );
  }
}

class HymnPopupMenuWidget extends StatelessWidget {
  final bool isFavorite;
  final bool canEditHymn;
  final bool isUserAuthenticated;
  final bool hasUserNote;
  final VoidCallback onToggleFavorite;
  final VoidCallback onEditHymn;
  final VoidCallback onShowNoteEditor;
  final VoidCallback onShowFontSizeSlider;
  final VoidCallback onShowColorPicker;
  final VoidCallback onShowAudioPlayer;
  final VoidCallback onAddToPlaylist;

  const HymnPopupMenuWidget({
    super.key,
    required this.isFavorite,
    required this.canEditHymn,
    required this.isUserAuthenticated,
    required this.hasUserNote,
    required this.onToggleFavorite,
    required this.onEditHymn,
    required this.onShowNoteEditor,
    required this.onShowFontSizeSlider,
    required this.onShowColorPicker,
    required this.onShowAudioPlayer,
    required this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return PopupMenuButton<String>(
      color: colorController.primaryColor.value.withValues(alpha: 0.9),
      icon: Icon(
        Icons.menu_sharp,
        color: colorController.iconColor.value,
      ),
      onSelected: (String item) {
        HapticFeedback.lightImpact();
        switch (item) {
          case 'edit':
            onEditHymn();
            break;
          case 'add_note':
            onShowNoteEditor();
            break;
          case 'font_size':
            onShowFontSizeSlider();
            break;
          case 'color_picker':
            onShowColorPicker();
            break;
          case 'audio_player':
            onShowAudioPlayer();
            break;
          case 'add_to_playlist':
            onAddToPlaylist();
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          if (canEditHymn)
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: colorController.textColor.value,
                  ),
                  const SizedBox(width: 8),
                   Text(context.translate((l) => l.edit)),
                ],
              ),
            ),
          if (isUserAuthenticated)
            PopupMenuItem<String>(
              value: 'add_note',
              child: Row(
                children: [
                  Icon(
                    hasUserNote ? Icons.edit_note : Icons.note_add,
                    color: colorController.textColor.value,
                  ),
                  const SizedBox(width: 8),
                   Text(hasUserNote ? context.translate((l) => l.editNote) : context.translate((l) => l.add)),
                ],
              ),
            ),
          PopupMenuItem<String>(
            value: 'font_size',
            child: Row(
              children: [
                Icon(
                  Icons.text_fields,
                  color: colorController.textColor.value,
                ),
                const SizedBox(width: 8),
                 Text(context.translate((l) => l.font)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'color_picker',
            child: Row(
              children: [
                Icon(
                  Icons.color_lens,
                  color: colorController.textColor.value,
                ),
                const SizedBox(width: 8),
                 Text(context.translate((l) => l.color)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'add_to_playlist',
            child: Row(
              children: [
                Icon(
                  Icons.playlist_add,
                  color: colorController.textColor.value,
                ),
                const SizedBox(width: 8),
                 Text(context.translate((l) => l.addToPlaylist)),
              ],
            ),
          ),
        ];
      },
    );
  }
}

class FavoriteButtonWidget extends StatelessWidget {
  final bool isFavorite;
  final String favoriteStatus;
  final VoidCallback onPressed;

  const FavoriteButtonWidget({
    super.key,
    required this.isFavorite,
    required this.favoriteStatus,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite
            ? Colors.red
            : colorController.iconColor.value,
      ),
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
    );
  }
}

class AudioButtonWidget extends StatelessWidget {
  final bool hasAudio;
  final bool isPlaying;
  final String hymnId;
  final VoidCallback onPressed;

  const AudioButtonWidget({
    super.key,
    required this.hasAudio,
    required this.isPlaying,
    required this.hymnId,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasAudio) return const SizedBox.shrink();

    return IconButton(
      icon: Stack(
        children: [
          Icon(
            Icons.music_note,
            color: isPlaying
                ? Theme.of(context).colorScheme.primary
                : Get.find<ColorController>().iconColor.value,
          ),
          if (isPlaying)
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
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
    );
  }
}
