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
    if (fonts.contains('Source Serif Pro')) {
      return 'Source Serif Pro';
    }
    if (fonts.contains('Lato')) {
      return 'Lato';
    }
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
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: [
                      _buildSelectionSummary(),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        key: _previewKey,
                        child: _buildPreviewCard(context),
                      ),
                      const SizedBox(height: 24),
                      _buildBackgroundSection(),
                      const SizedBox(height: 20),
                      _buildSliderSection(
                        context: context,
                        title: l10n.backgroundTransparency,
                        valueLabel: '${(_backgroundOpacity * 100).round()}%',
                        icon: Icons.opacity_rounded,
                        value: _backgroundOpacity,
                        min: 0.35,
                        max: 1.0,
                        onChanged: (value) {
                          setState(() => _backgroundOpacity = value);
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildSliderSection(
                        context: context,
                        title: l10n.fontSize,
                        valueLabel: '${_fontSize.round()}',
                        icon: Icons.text_fields_rounded,
                        value: _fontSize,
                        min: 16,
                        max: 32,
                        onChanged: (value) {
                          setState(() => _fontSize = value);
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildTextColorSection(context),
                      const SizedBox(height: 20),
                      _buildFontSection(context),
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
            colors: [
              color,
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        children: [
          _buildIconButton(
            icon: Icons.close_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.verseStudio,
                  style: TextStyle(
                    color: colorController.textColor.value,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.shapeThePassageBeforeYouShareIt,
                  style: TextStyle(
                    color:
                        colorController.textColor.value.withValues(alpha: 0.72),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorController.primaryColor.value.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    colorController.primaryColor.value.withValues(alpha: 0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.data.reference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorController.textColor.value,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.data.verseCountLabel,
                  style: TextStyle(
                    color:
                        colorController.textColor.value.withValues(alpha: 0.70),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorController.primaryColor.value.withValues(alpha: 0.10),
            _selectedBackground.accent.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: colorController.primaryColor.value.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorController.primaryColor.value.withValues(alpha: 0.14),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: colorController.primaryColor.value,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.data.reference,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorController.textColor.value,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
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
                    ? Image.file(
                        File(_customImagePath!),
                        fit: BoxFit.cover,
                      )
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _textColor.withValues(alpha: 0.12),
              border: Border.all(
                color: _textColor.withValues(alpha: 0.16),
              ),
            ),
            child: Center(
              child: Text(
                verse.number.toString(),
                style: TextStyle(
                  color: _textColor,
                  fontSize: 12,
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

  Widget _buildBackgroundSection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.background,
          style: TextStyle(
            color: colorController.textColor.value,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _backgrounds.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCustomImageCard();
              }
              final preset = _backgrounds[index - 1];
              final isSelected = _customImagePath == null &&
                  preset.id == _selectedBackgroundId;
              return _buildBackgroundCard(preset, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomImageCard() {
    final isSelected = _customImagePath != null;
    return GestureDetector(
      onTap: _pickCustomImage,
      child: AnimatedContainer(
        duration: AppDimensions.normal,
        width: 95,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: colorController.primaryColor.value.withValues(alpha: 0.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.16 : 0.08),
              blurRadius: isSelected ? 18 : 10,
              offset: const Offset(0, 8),
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
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              if (_customImagePath != null)
                Positioned.fill(
                  child: Image.file(
                    File(_customImagePath!),
                    fit: BoxFit.cover,
                  ),
                )
              else
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        color: colorController.primaryColor.value,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Builder(
                        builder: (context) => Text(
                          AppLocalizations.of(context).customImage,
                          style: TextStyle(
                            color: colorController.textColor.value,
                            fontSize: 12,
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
                          Colors.black.withValues(alpha: 0.34),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_customImagePath != null)
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 12,
                  child: Builder(
                    builder: (context) => Text(
                      AppLocalizations.of(context).customImage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (isSelected)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorController.primaryColor.value,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _customImagePath = result.files.single.path;
      });
    }
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
        width: 95,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.16 : 0.08),
              blurRadius: isSelected ? 18 : 10,
              offset: const Offset(0, 8),
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
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.asset(
                  preset.assetPath,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.10),
                        Colors.black.withValues(alpha: 0.34),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 26,
                      height: 4,
                      decoration: BoxDecoration(
                        color: preset.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorController.primaryColor.value,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderSection({
    required BuildContext context,
    required String title,
    required String valueLabel,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorController.backgroundColor.value.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorController.primaryColor.value.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorController.primaryColor.value),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colorController.textColor.value,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                valueLabel,
                style: TextStyle(
                  color:
                      colorController.textColor.value.withValues(alpha: 0.68),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colorController.primaryColor.value,
              inactiveTrackColor:
                  colorController.primaryColor.value.withValues(alpha: 0.16),
              thumbColor: colorController.primaryColor.value,
              overlayColor:
                  colorController.primaryColor.value.withValues(alpha: 0.14),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextColorSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context).chooseTextColor,
              style: TextStyle(
                color: colorController.textColor.value,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.palette_rounded,
              size: 16,
              color: colorController.primaryColor.value,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                colorController.backgroundColor.value.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorController.primaryColor.value.withValues(alpha: 0.08),
            ),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ..._textColorOptions.map(
                (color) => _buildColorOption(color),
              ),
              _buildCustomColorButton(context),
            ],
          ),
        ),
      ],
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
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: colorController.textColor.value,
            size: 20,
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
        width: 42,
        height: 42,
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
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isSelected
            ? const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 18,
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCustomColorButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showCustomColorPicker(context),
      child: Container(
        width: 42,
        height: 42,
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
          size: 20,
        ),
      ),
    );
  }

  Widget _buildFontSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context).fontFamily,
              style: TextStyle(
                color: colorController.textColor.value,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.font_download_rounded,
              size: 16,
              color: colorController.primaryColor.value,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 54,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: fontController.availableFonts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final font = fontController.availableFonts[index];
              final isSelected = font == _fontFamily;
              return _buildFontChip(font, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFontChip(String font, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _fontFamily = font),
      child: AnimatedContainer(
        duration: AppDimensions.normal,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
                        .withValues(alpha: 0.18),
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
      setState(() {
        _isSharing = true;
      });

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
            XFile.fromData(
              pngBytes,
              name: 'bible-share.png',
              mimeType: 'image/png',
            ),
          ],
          text: widget.data.shareText,
          subject: widget.data.shareSubject,
        ),
      );

      if (!mounted) {
        return;
      }

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
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
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
                      onColorChanged: (color) {
                        tempColor = color;
                      },
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
      setState(() {
        _textColor = pickedColor;
      });
    }
  }
}

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
      gradient: [
        Color(0xFFFF9E80),
        Color(0xFFFFD166),
      ],
    ),
    BibleShareBackgroundPreset(
      id: 'aurora',
      label: 'Aurora',
      assetPath: 'assets/images/bible_share/aurora.svg',
      accent: Color(0xFF80FFDB),
      gradient: [
        Color(0xFF5E60CE),
        Color(0xFF48BFE3),
      ],
    ),
    BibleShareBackgroundPreset(
      id: 'midnight',
      label: 'Midnight',
      assetPath: 'assets/images/bible_share/midnight.svg',
      accent: Color(0xFF8ECAE6),
      gradient: [
        Color(0xFF0D1B2A),
        Color(0xFF1B263B),
      ],
    ),
    BibleShareBackgroundPreset(
      id: 'olive',
      label: 'Olive',
      assetPath: 'assets/images/bible_share/olive.svg',
      accent: Color(0xFF95D5B2),
      gradient: [
        Color(0xFF1B4332),
        Color(0xFF40916C),
      ],
    ),
    BibleShareBackgroundPreset(
      id: 'parchment',
      label: 'Parchment',
      assetPath: 'assets/images/bible_share/parchment.svg',
      accent: Color(0xFFD4A373),
      gradient: [
        Color(0xFFF5E9D3),
        Color(0xFFEAD2AC),
      ],
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
