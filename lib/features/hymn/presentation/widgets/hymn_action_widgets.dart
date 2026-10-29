import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/shared/widgets/common/localization_extension.dart';

/// The reader's font-size control. The number it drags to is set in the figure
/// family so the value does not jump about while you slide.
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
    final AppSurfaces s = AppSurfaces.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Text('A',
            style: textTheme.bodySmall
                ?.copyWith(color: s.muted, fontWeight: FontWeight.w700)),
        Expanded(
          child: Slider(
            value: fontSize,
            min: 8,
            max: 50,
            divisions: 56,
            label: fontSize.toStringAsFixed(1),
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        Text('A', style: textTheme.titleLarge?.copyWith(color: s.muted)),
      ],
    );
  }
}

/// The overflow menu on the sheet. It is a plain control; the menu it opens is
/// styled by the theme, not by a box drawn around each row.
class HymnPopupMenuWidget extends StatelessWidget {
  final bool canEditHymn;
  final bool isUserAuthenticated;
  final bool hasUserNote;
  final VoidCallback onEditHymn;
  final VoidCallback onShowNoteEditor;
  final VoidCallback onShowFontSizeSlider;
  final VoidCallback onShowColorPicker;
  final VoidCallback onShowAudioPlayer;
  final VoidCallback onAddToPlaylist;

  const HymnPopupMenuWidget({
    super.key,
    required this.canEditHymn,
    required this.isUserAuthenticated,
    required this.hasUserNote,
    required this.onEditHymn,
    required this.onShowNoteEditor,
    required this.onShowFontSizeSlider,
    required this.onShowColorPicker,
    required this.onShowAudioPlayer,
    required this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: context.translate((l) => l.moreActions),
      offset: const Offset(0, AppScale.appBarHeight),
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
            _item('edit', Icons.edit_rounded, context.translate((l) => l.edit)),
          if (isUserAuthenticated)
            _item(
              'add_note',
              hasUserNote ? Icons.edit_note_rounded : Icons.note_add_rounded,
              hasUserNote
                  ? context.translate((l) => l.editNote)
                  : context.translate((l) => l.add),
            ),
          _item('font_size', Icons.format_size_rounded,
              context.translate((l) => l.font)),
          _item('color_picker', Icons.palette_rounded,
              context.translate((l) => l.color)),
          _item('add_to_playlist', Icons.playlist_add_rounded,
              context.translate((l) => l.addToPlaylist)),
        ];
      },
      icon: const Icon(Icons.more_vert_rounded, size: AppScale.iconLg),
    );
  }

  PopupMenuItem<String> _item(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: AppScale.iconMd),
          const SizedBox(width: AppScale.space16),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

/// Bookmarks the hymn. State is the glyph and its ink, nothing else.
class FavoriteButtonWidget extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onPressed;

  const FavoriteButtonWidget({
    super.key,
    required this.isFavorite,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);
    return IconButton(
      tooltip: context.translate((l) => l.favorites),
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      icon: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: AppScale.iconLg,
        color: isFavorite ? s.accent : s.ink,
      ),
      style: IconButton.styleFrom(
          minimumSize: const Size(AppScale.hitTarget, AppScale.hitTarget)),
    );
  }
}

/// Opens the player for this hymn. While it plays the glyph is the whole
/// signal; a light is not needed to say a sound is coming out of the phone.
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

    final AppSurfaces s = AppSurfaces.of(context);
    return IconButton(
      tooltip: context.translate((l) => l.playAudio),
      onPressed: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      icon: Icon(
        isPlaying ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
        size: AppScale.iconLg,
        color: isPlaying ? s.accent : s.ink,
      ),
      style: IconButton.styleFrom(
          minimumSize: const Size(AppScale.hitTarget, AppScale.hitTarget)),
    );
  }
}
