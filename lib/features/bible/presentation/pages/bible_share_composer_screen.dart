import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/app/theme/font_controller.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';
import 'package:fihirana/features/bible/presentation/models/bible_share_data.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class BibleShareComposerScreen extends StatefulWidget {
  final BibleShareData data;

  const BibleShareComposerScreen({
    super.key,
    required this.data,
  });

  @override
  State<BibleShareComposerScreen> createState() =>
      _BibleShareComposerScreenState();
}

class _BibleShareComposerScreenState extends State<BibleShareComposerScreen> {
  final GlobalKey _previewKey = GlobalKey();

  final ColorController colorController = Get.find<ColorController>();
  final FontController fontController = Get.find<FontController>();

  late final List<BibleShareBackgroundPreset> _backgrounds =
      BibleShareBackgroundPreset.presets;

  late String _selectedBackgroundId;
  late double _backgroundOpacity;
  late double _fontSize;
  late Color _textColor;
  late String _fontFamily;
  String? _customImagePath;
  bool _isSharing = false;

  BibleShareBackgroundPreset get _selectedBackground =>
      _backgrounds.firstWhere((preset) => preset.id == _selectedBackgroundId);

  @override
  void initState() {
    super.initState();
    _selectedBackgroundId = _backgrounds.first.id;
    _backgroundOpacity = 0.92;
    _fontSize = 22;
    _textColor = colorController.textColor.value;
    _fontFamily = _resolveDefaultFont();
  }

  String _resolveDefaultFont() {
    final fonts = fontController.availableFonts;
    if (fonts.contains('Source Serif Pro')) return 'Source Serif Pro';
    if (fonts.contains('Lato')) return 'Lato';
    return fonts.first;
  }

  bool get _textIsLight => _textColor.computeLuminance() > 0.5;

  Color get _panelColor => _textIsLight
      ? Colors.black.withValues(alpha: 0.24)
      : Colors.white.withValues(alpha: 0.52);

  List<Shadow> get _textShadows => [
        Shadow(
          color: (_textIsLight ? Colors.black : Colors.white)
              .withValues(alpha: 0.30),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ];

  // ─── Shared panel decoration ──────────────────────────────────────────────
  BoxDecoration get _panelDecoration => BoxDecoration(
        color: colorController.backgroundColor.value.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorController.primaryColor.value.withValues(alpha: 0.10),
        ),
      );

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackdrop()),
          Positioned(
            top: -70,
            right: -40,
            child: _buildGlowBlob(
              _selectedBackground.gradient.last.withValues(alpha: 0.28),
              220,
            ),
          ),
          Positioned(
            bottom: 120,
            left: -50,
            child: _buildGlowBlob(
              _selectedBackground.accent.withValues(alpha: 0.20),
              180,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, l10n),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    children: [
                      // ── Preview ──────────────────────────────────────────
                      RepaintBoundary(
                        key: _previewKey,
                        child: _buildPreviewCard(),
                      ),
                      const SizedBox(height: 24),

                      // ── Background picker ─────────────────────────────────
                      _buildSectionLabel(
                        l10n.background,
                        Icons.wallpaper_rounded,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 116,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _backgrounds.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            if (index == 0) return _buildCustomImageCard();
                            final preset = _backgrounds[index - 1];
                            final isSelected = _customImagePath == null &&
                                preset.id == _selectedBackgroundId;
                            return _buildBackgroundCard(preset, isSelected);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Style panel (all controls unified) ───────────────
                      _buildSectionLabel(
                        'Style',
                        Icons.tune_rounded,
                      ),
                      const SizedBox(height: 10),
                      _buildStylePanel(context, l10n),
                    ],
                  ),
                ),
                _buildFooter(context, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Row(
        children: [
          _buildIconButton(
            icon: Icons.close_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.verseStudio,
              style: TextStyle(
                color: colorController.textColor.value,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          // Reference pill — the ONE place we show it in the header
          Container(
            constraints: const BoxConstraints(maxWidth: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorController.primaryColor.value.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    colorController.primaryColor.value.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.data.reference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorController.textColor.value,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.data.verseCountLabel,
                  style: TextStyle(
                    color:
                        colorController.textColor.value.withValues(alpha: 0.60),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section label helper ─────────────────────────────────────────────────
  Widget _buildSectionLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: colorController.primaryColor.value),
        const SizedBox(width: 7),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: colorController.primaryColor.value,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  // ─── Backdrop / blobs ─────────────────────────────────────────────────────
  Widget _buildBackdrop() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorController.backgroundColor.value,
            _selectedBackground.gradient.first.withValues(alpha: 0.14),
            _selectedBackground.gradient.last.withValues(alpha: 0.08),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowBlob(Color color, double size) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }

  // ─── Preview card ─────────────────────────────────────────────────────────
  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: _backgroundOpacity,
                child: _customImagePath != null
                    ? Image.file(File(_customImagePath!), fit: BoxFit.cover)
                    : SvgPicture.asset(
                        _selectedBackground.assetPath,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.06),
                      Colors.black.withValues(alpha: 0.22),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.data.reference,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: fontController.getFontStyle(
                            'Montserrat',
                            TextStyle(
                              color: _textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              shadows: _textShadows,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _panelColor,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _textColor.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(
                          widget.data.verseCountLabel.toUpperCase(),
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            shadows: _textShadows,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _panelColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.data.verses
                          .map((verse) => _buildVerseLine(verse))
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(DateTime.now()),
                      style: TextStyle(
                        color: _textColor.withValues(alpha: 0.82),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        shadows: _textShadows,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseLine(BibleShareVerseLine verse) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _textColor.withValues(alpha: 0.12),
              border: Border.all(color: _textColor.withValues(alpha: 0.16)),
            ),
            child: Center(
              child: Text(
                verse.number.toString(),
                style: TextStyle(
                  color: _textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  shadows: _textShadows,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              verse.text,
              style: fontController.getFontStyle(
                _fontFamily,
                TextStyle(
                  color: _textColor,
                  fontSize: _fontSize,
                  height: 1.55,
                  shadows: _textShadows,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Background cards ─────────────────────────────────────────────────────
  Widget _buildCustomImageCard() {
    final isSelected = _customImagePath != null;
    return GestureDetector(
      onTap: _pickCustomImage,
      child: AnimatedContainer(
        duration: AppDimensions.normal,
        width: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: colorController.primaryColor.value.withValues(alpha: 0.08),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.16 : 0.06),
              blurRadius: isSelected ? 18 : 8,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isSelected
                ? colorController.primaryColor.value
                : colorController.primaryColor.value.withValues(alpha: 0.15),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              if (_customImagePath != null)
                Positioned.fill(
                  child: Image.file(File(_customImagePath!), fit: BoxFit.cover),
                )
              else
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        color: colorController.primaryColor.value,
                        size: 26,
                      ),
                      const SizedBox(height: 5),
                      Builder(
                        builder: (ctx) => Text(
                          AppLocalizations.of(ctx).customImage,
                          style: TextStyle(
                            color: colorController.textColor.value,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_customImagePath != null)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.10),
                          Colors.black.withValues(alpha: 0.38),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_customImagePath != null)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 10,
                  child: Builder(
                    builder: (ctx) => Text(
                      AppLocalizations.of(ctx).customImage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (isSelected) _buildCheckBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundCard(
    BibleShareBackgroundPreset preset,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => setState(() {
        _customImagePath = null;
        _selectedBackgroundId = preset.id;
      }),
      child: AnimatedContainer(
        duration: AppDimensions.normal,
        width: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.16 : 0.06),
              blurRadius: isSelected ? 18 : 8,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: isSelected
                ? colorController.primaryColor.value
                : colorController.primaryColor.value.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.asset(preset.assetPath, fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.06),
                        Colors.black.withValues(alpha: 0.36),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 22,
                      height: 3,
                      decoration: BoxDecoration(
                        color: preset.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected) _buildCheckBadge(),
            ],
          ),
        ),
      ),
    );
  }

  /// Shared selection-check badge used on both card types.
  Widget _buildCheckBadge() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: colorController.primaryColor.value,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
      ),
    );
  }

  Future<void> _pickCustomImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _customImagePath = result.files.single.path);
    }
  }

  // ─── Unified Style panel ──────────────────────────────────────────────────
  /// All four customisation controls live in ONE card with thin dividers.
  Widget _buildStylePanel(BuildContext context, AppLocalizations l10n) {
    final divider = Divider(
      height: 1,
      thickness: 0.8,
      color: colorController.primaryColor.value.withValues(alpha: 0.08),
    );

    return Container(
      decoration: _panelDecoration,
      child: Column(
        children: [
          // 1 ── Opacity slider
          _buildInlineSlider(
            context: context,
            icon: Icons.opacity_rounded,
            label: l10n.backgroundTransparency,
            valueLabel: '${(_backgroundOpacity * 100).round()}%',
            value: _backgroundOpacity,
            min: 0.35,
            max: 1.0,
            onChanged: (v) => setState(() => _backgroundOpacity = v),
          ),
          divider,
          // 2 ── Font size slider
          _buildInlineSlider(
            context: context,
            icon: Icons.text_fields_rounded,
            label: l10n.fontSize,
            valueLabel: '${_fontSize.round()}',
            value: _fontSize,
            min: 16,
            max: 32,
            onChanged: (v) => setState(() => _fontSize = v),
          ),
          divider,
          // 3 ── Text color
          _buildInlineColorRow(context, l10n),
          divider,
          // 4 ── Font family
          _buildInlineFontRow(),
        ],
      ),
    );
  }

  Widget _buildInlineSlider({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colorController.primaryColor.value),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colorController.textColor.value,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                valueLabel,
                style: TextStyle(
                  color: colorController.primaryColor.value,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colorController.primaryColor.value,
              inactiveTrackColor:
                  colorController.primaryColor.value.withValues(alpha: 0.15),
              thumbColor: colorController.primaryColor.value,
              overlayColor:
                  colorController.primaryColor.value.withValues(alpha: 0.12),
              trackHeight: 3,
            ),
            child:
                Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineColorRow(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_rounded,
                  size: 16, color: colorController.primaryColor.value),
              const SizedBox(width: 9),
              Text(
                l10n.chooseTextColor,
                style: TextStyle(
                  color: colorController.textColor.value,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ..._textColorOptions.map(_buildColorOption),
              _buildCustomColorButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineFontRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 0, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.font_download_rounded,
                  size: 16, color: colorController.primaryColor.value),
              const SizedBox(width: 9),
              Builder(
                builder: (ctx) => Text(
                  AppLocalizations.of(ctx).fontFamily,
                  style: TextStyle(
                    color: colorController.textColor.value,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 18),
              itemCount: fontController.availableFonts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final font = fontController.availableFonts[i];
                return _buildFontChip(font, font == _fontFamily);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Small reusable sub-widgets ───────────────────────────────────────────
  Widget _buildFontChip(String font, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _fontFamily = font),
      child: AnimatedContainer(
        duration: AppDimensions.normal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorController.primaryColor.value
              : colorController.primaryColor.value.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? colorController.primaryColor.value
                : colorController.primaryColor.value.withValues(alpha: 0.10),
          ),
        ),
        child: Text(
          font,
          style: fontController.getFontStyle(
            font,
            TextStyle(
              color:
                  isSelected ? Colors.white : colorController.textColor.value,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    final isSelected = color.toARGB32() == _textColor.toARGB32();
    return GestureDetector(
      onTap: () => setState(() => _textColor = color),
      child: AnimatedContainer(
        duration: AppDimensions.normal,
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isSelected
                ? colorController.primaryColor.value
                : Colors.white.withValues(alpha: 0.25),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.16 : 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCustomColorButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCustomColorPicker(context),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorController.primaryColor.value.withValues(alpha: 0.10),
          border: Border.all(
            color: colorController.primaryColor.value.withValues(alpha: 0.24),
          ),
        ),
        child: Icon(
          Icons.tune_rounded,
          color: colorController.primaryColor.value,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: colorController.primaryColor.value.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: colorController.textColor.value,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ─── Footer ───────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSharing ? null : _copyShareText,
                icon: const Icon(Icons.copy_rounded),
                label: Text(l10n.copy),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorController.textColor.value,
                  side: BorderSide(
                    color: colorController.primaryColor.value
                        .withValues(alpha: 0.20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _isSharing ? null : _shareAsImage,
                icon: _isSharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.share_rounded),
                label: Text(_isSharing ? l10n.preparing : l10n.share),
                style: FilledButton.styleFrom(
                  backgroundColor: colorController.primaryColor.value,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────
  Future<void> _copyShareText() async {
    await Clipboard.setData(ClipboardData(text: widget.data.shareText));
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    Get.snackbar(
      l10n.copied,
      l10n.passageTextCopied,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: colorController.primaryColor.value,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
    );
  }

  Future<void> _shareAsImage() async {
    try {
      setState(() => _isSharing = true);

      await WidgetsBinding.instance.endOfFrame;
      final renderObject = _previewKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError('Unable to capture the preview card.');
      }

      final image = await renderObject.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw StateError('Failed to encode the preview image.');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(pngBytes,
                name: 'bible-share.png', mimeType: 'image/png'),
          ],
          text: widget.data.shareText,
          subject: widget.data.shareSubject,
        ),
      );

      if (!mounted) return;
      final l10n = AppLocalizations.of(context);

      if (result.status == ShareResultStatus.unavailable) {
        Get.snackbar(
          l10n.sharingUnavailable,
          l10n.tryCopyingPassage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
        );
      }
    } catch (error) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Get.snackbar(
          l10n.shareFailed,
          error.toString(),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 14,
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _showCustomColorPicker(BuildContext context) async {
    final pickedColor = await showDialog<Color>(
      context: context,
      builder: (context) {
        var tempColor = _textColor;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            decoration: BoxDecoration(
              color: colorController.backgroundColor.value,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    colorController.primaryColor.value.withValues(alpha: 0.18),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).chooseTextColor,
                    style: TextStyle(
                      color: colorController.textColor.value,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    child: MaterialPicker(
                      pickerColor: tempColor,
                      onColorChanged: (c) => tempColor = c,
                      enableLabel: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(tempColor),
                      child: Text(
                        AppLocalizations.of(context).apply,
                        style: TextStyle(
                          color: colorController.primaryColor.value,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (pickedColor != null && mounted) {
      setState(() => _textColor = pickedColor);
    }
  }
}

// ─── Data models ─────────────────────────────────────────────────────────────

class BibleShareBackgroundPreset {
  final String id;
  final String label;
  final String assetPath;
  final Color accent;
  final List<Color> gradient;

  const BibleShareBackgroundPreset({
    required this.id,
    required this.label,
    required this.assetPath,
    required this.accent,
    required this.gradient,
  });

  static const List<BibleShareBackgroundPreset> presets = [
    BibleShareBackgroundPreset(
      id: 'dawn',
      label: 'Dawn',
      assetPath: 'assets/images/bible_share/dawn.svg',
      accent: Color(0xFFFFB703),
      gradient: [Color(0xFFFF9E80), Color(0xFFFFD166)],
    ),
    BibleShareBackgroundPreset(
      id: 'aurora',
      label: 'Aurora',
      assetPath: 'assets/images/bible_share/aurora.svg',
      accent: Color(0xFF80FFDB),
      gradient: [Color(0xFF5E60CE), Color(0xFF48BFE3)],
    ),
    BibleShareBackgroundPreset(
      id: 'midnight',
      label: 'Midnight',
      assetPath: 'assets/images/bible_share/midnight.svg',
      accent: Color(0xFF8ECAE6),
      gradient: [Color(0xFF0D1B2A), Color(0xFF1B263B)],
    ),
    BibleShareBackgroundPreset(
      id: 'olive',
      label: 'Olive',
      assetPath: 'assets/images/bible_share/olive.svg',
      accent: Color(0xFF95D5B2),
      gradient: [Color(0xFF1B4332), Color(0xFF40916C)],
    ),
    BibleShareBackgroundPreset(
      id: 'parchment',
      label: 'Parchment',
      assetPath: 'assets/images/bible_share/parchment.svg',
      accent: Color(0xFFD4A373),
      gradient: [Color(0xFFF5E9D3), Color(0xFFEAD2AC)],
    ),
  ];
}

const List<Color> _textColorOptions = [
  Colors.white,
  Color(0xFFF5E6C8),
  Color(0xFFF8F4EC),
  Color(0xFF121212),
  Color(0xFF3E2723),
  Color(0xFF5D4037),
  Color(0xFFD4AF37),
  Color(0xFFB39DDB),
];
