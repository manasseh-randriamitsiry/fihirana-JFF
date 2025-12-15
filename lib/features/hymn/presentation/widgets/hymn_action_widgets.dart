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

    return Row(
      children: [
        Icon(
          Icons.text_decrease,
          color: colorController.textColor.value.withValues(alpha: 0.6),
          size: 20,
        ),
        Expanded(
          child: Slider(
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
          ),
        ),
        Icon(
          Icons.text_increase,
          color: colorController.textColor.value.withValues(alpha: 0.6),
          size: 20,
        ),
      ],
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
    final backgroundColor = colorController.backgroundColor.value;
    final primaryColor = colorController.primaryColor.value;
    final textColor = colorController.textColor.value;

    return Container(
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: PopupMenuButton<String>(
        color: backgroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        offset: const Offset(0, 48),
        icon: Icon(
          Icons.more_vert_rounded,
          color: primaryColor,
          size: 22,
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
              _buildMenuItem(
                value: 'edit',
                icon: Icons.edit_rounded,
                label: context.translate((l) => l.edit),
                textColor: textColor,
                primaryColor: primaryColor,
              ),
            if (isUserAuthenticated)
              _buildMenuItem(
                value: 'add_note',
                icon: hasUserNote ? Icons.edit_note_rounded : Icons.note_add_rounded,
                label: hasUserNote
                    ? context.translate((l) => l.editNote)
                    : context.translate((l) => l.add),
                textColor: textColor,
                primaryColor: primaryColor,
              ),
            _buildMenuItem(
              value: 'font_size',
              icon: Icons.format_size_rounded,
              label: context.translate((l) => l.font),
              textColor: textColor,
              primaryColor: primaryColor,
            ),
            _buildMenuItem(
              value: 'color_picker',
              icon: Icons.palette_rounded,
              label: context.translate((l) => l.color),
              textColor: textColor,
              primaryColor: primaryColor,
            ),
            _buildMenuItem(
              value: 'add_to_playlist',
              icon: Icons.playlist_add_rounded,
              label: context.translate((l) => l.addToPlaylist),
              textColor: textColor,
              primaryColor: primaryColor,
            ),
          ];
        },
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String value,
    required IconData icon,
    required String label,
    required Color textColor,
    required Color primaryColor,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteButtonWidget extends StatefulWidget {
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
  State<FavoriteButtonWidget> createState() => _FavoriteButtonWidgetState();
}

class _FavoriteButtonWidgetState extends State<FavoriteButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _controller.forward().then((_) => _controller.reverse());
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final primaryColor = colorController.primaryColor.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: widget.isFavorite
                ? Colors.red.withValues(alpha: 0.12)
                : primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Icon(
              widget.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: widget.isFavorite ? Colors.red : primaryColor,
              size: 22,
            ),
          ),
        ),
      ),
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

    final colorController = Get.find<ColorController>();
    final primaryColor = colorController.primaryColor.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPlaying
                ? primaryColor.withValues(alpha: 0.15)
                : primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: isPlaying
                ? Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  isPlaying ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                  key: ValueKey(isPlaying),
                  color: primaryColor,
                  size: 22,
                ),
              ),
              if (isPlaying) ...[
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A stylized action button for the hymn detail screen
class HymnActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final bool isActive;
  final Color? activeColor;

  const HymnActionButton({
    super.key,
    required this.icon,
    this.label,
    required this.onPressed,
    this.isActive = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final primaryColor = colorController.primaryColor.value;
    final effectiveActiveColor = activeColor ?? primaryColor;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? effectiveActiveColor.withValues(alpha: 0.15)
              : primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(color: effectiveActiveColor.withValues(alpha: 0.3), width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? effectiveActiveColor : primaryColor,
              size: 20,
            ),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: TextStyle(
                  color: isActive ? effectiveActiveColor : primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
