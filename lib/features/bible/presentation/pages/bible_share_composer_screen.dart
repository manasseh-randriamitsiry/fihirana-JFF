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

import 'package:fihirana/app/theme/font_controller.dart';
import 'package:fihirana/core/design_system/app_scale.dart';
import 'package:fihirana/core/design_system/app_surfaces.dart';
import 'package:fihirana/core/design_system/app_typography.dart';
import 'package:fihirana/core/design_system/components/app_sheet.dart';
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

  final FontController fontController = Get.find<FontController>();

  late final List<BibleShareBackgroundPreset> _backgrounds =
      BibleShareBackgroundPreset.presets;

  late String _selectedBackgroundId;
  late double _backgroundOpacity;
  late double _fontSize;
  Color? _textColor;
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
    _fontSize = AppTypography.lyric;
    _fontFamily = _resolveDefaultFont();
  }

  /// A picked photo the decoder cannot read falls back to the same flat
  /// placeholder an empty custom slot shows, so the strip never goes blank.
  Widget _customImage(File file, Color fill, Color icon) => Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ColoredBox(
          color: fill,
          child: Icon(Icons.broken_image_outlined,
              size: AppScale.iconLg, color: icon),
        ),
      );

  String _resolveDefaultFont() {
    final fonts = fontController.availableFonts;
    if (fonts.contains('Source Serif Pro')) return 'Source Serif Pro';
    if (fonts.contains('Lato')) return 'Lato';
    return fonts.first;
  }

  /// The ink the passage is set in. It starts on the theme's own ink, so the
  /// plate matches whichever scheme the user picked in Settings.
  Color get _ink => _textColor ?? AppSurfaces.of(context).ink;

  bool get _textIsLight => _ink.computeLuminance() > 0.5;

  /// The panel and the shadows are part of the exported picture, not of the
  /// app's chrome: they are what keeps the words legible over any photo.
  Color get _panelColor => _textIsLight
      ? Colors.black.withValues(alpha: 0.24)
      : Colors.white.withValues(alpha: 0.52);

  List<Shadow> get _textShadows => [
        Shadow(
          color: (_textIsLight ? Colors.black : Colors.white)
              .withValues(alpha: 0.30),
          blurRadius: AppScale.blurFloat,
          offset: const Offset(0, AppScale.space4),
        ),
      ];

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppSurfaces.of(context).paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, l10n),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxWidth: AppScale.workMeasure),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: AppScale.space24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppScale.gutter,
                            AppScale.space16, AppScale.gutter, 0),
                        child: RepaintBoundary(
                          key: _previewKey,
                          child: _buildPlate(context),
                        ),
                      ),
                      AppGroupHead(title: l10n.background),
                      SizedBox(
                        height: AppScale.swatchTall + AppScale.space24,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppScale.gutter),
                          itemCount: _backgrounds.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppScale.space12),
                          itemBuilder: (context, index) {
                            if (index == 0) return _buildCustomTile(l10n);
                            final preset = _backgrounds[index - 1];
                            return _StudioTile(
                              label: preset.label,
                              selected: _customImagePath == null &&
                                  preset.id == _selectedBackgroundId,
                              onTap: () => setState(() {
                                _customImagePath = null;
                                _selectedBackgroundId = preset.id;
                              }),
                              preview:
                                  SvgPicture.asset(preset.assetPath,
                                      fit: BoxFit.cover),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppScale.gutter, AppScale.space24, AppScale.gutter,
                            0),
                        child: _buildControlGroup(l10n),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(context, l10n),
          ],
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final TextTheme type = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppScale.space8, AppScale.space8, AppScale.gutter,
              AppScale.space12),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.close,
              ),
              const SizedBox(width: AppScale.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.verseStudio, style: type.titleLarge),
                    const SizedBox(height: AppScale.space2),
                    Text(l10n.shapeThePassageBeforeYouShareIt,
                        style: type.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const AppRule(firm: true),
      ],
    );
  }

  // ─── The plate ─────────────────────────────────────────────────────────────
  Widget _buildPlate(BuildContext context) {
    final Color ink = _ink;
    final AppSurfaces s = AppSurfaces.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppScale.radiusSheet),
        border: Border.all(color: ink.withValues(alpha: 0.18)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppScale.radiusSheet),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: _backgroundOpacity,
                child: _customImagePath != null
                    ? _customImage(File(_customImagePath!), s.paper2, s.muted)
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
              padding: const EdgeInsets.all(AppScale.space24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.reference,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: fontController.getFontStyle(
                      'Montserrat',
                      TextStyle(
                        color: ink,
                        fontSize: AppTypography.headline,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        shadows: _textShadows,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppScale.space16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppScale.space16),
                    decoration: BoxDecoration(
                      color: _panelColor,
                      borderRadius:
                          BorderRadius.circular(AppScale.radiusRow),
                      border: Border.all(color: ink.withValues(alpha: 0.12)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.data.verses
                          .map((verse) => _buildVerseLine(verse, ink, s))
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: AppScale.space16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          widget.data.verseCountLabel,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: ink.withValues(alpha: 0.82),
                                  shadows: _textShadows),
                        ),
                      ),
                      const SizedBox(width: AppScale.space12),
                      Text(
                        DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: ink.withValues(alpha: 0.82),
                              shadows: _textShadows,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerseLine(BibleShareVerseLine verse, Color ink, AppSurfaces s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppScale.space16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppScale.controlDense,
            height: AppScale.controlDense,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ink.withValues(alpha: 0.12),
              border: Border.all(color: ink.withValues(alpha: 0.16)),
            ),
            child: Center(
              child: Text(
                verse.number.toString(),
                style: AppTypography.figure(
                  s,
                  size: AppScale.figureSm,
                  weight: FontWeight.w700,
                  color: ink,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppScale.space12),
          Expanded(
            child: Text(
              verse.text,
              style: fontController.getFontStyle(
                _fontFamily,
                TextStyle(
                  color: ink,
                  fontSize: _fontSize,
                  height: AppTypography.lyricLead,
                  shadows: _textShadows,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Background strip ──────────────────────────────────────────────────────
  Widget _buildCustomTile(AppLocalizations l10n) {
    final AppSurfaces s = AppSurfaces.of(context);

    return _StudioTile(
      label: l10n.customImage,
      selected: _customImagePath != null,
      onTap: _pickCustomImage,
      preview: _customImagePath != null
          ? _customImage(File(_customImagePath!), s.paper2, s.muted)
          : ColoredBox(
              color: s.paper2,
              child: Icon(Icons.add_photo_alternate_rounded,
                  size: AppScale.iconLg, color: s.muted),
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

  // ─── Control group ─────────────────────────────────────────────────────────
  Widget _buildControlGroup(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppRule(firm: true),
        _sliderRow(
          label: l10n.backgroundTransparency,
          // The slider holds the opacity; the read-out answers to its label.
          valueLabel: '${((1 - _backgroundOpacity) * 100).round()}%',
          value: _backgroundOpacity,
          min: 0.35,
          max: 1.0,
          onChanged: (v) => setState(() => _backgroundOpacity = v),
        ),
        const AppRule(indent: AppScale.space16),
        _sliderRow(
          label: l10n.fontSize,
          valueLabel: '${_fontSize.round()}',
          value: _fontSize,
          min: AppTypography.body,
          max: AppTypography.display,
          onChanged: (v) => setState(() => _fontSize = v),
        ),
        const AppRule(indent: AppScale.space16),
        _colorRow(l10n),
        const AppRule(indent: AppScale.space16),
        _fontRow(l10n),
      ],
    );
  }

  Widget _sliderRow({
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final AppSurfaces s = AppSurfaces.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppScale.space16, AppScale.space12,
          AppScale.space16, AppScale.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              Text(valueLabel,
                  style: AppTypography.figure(s, size: AppScale.figureSm)),
            ],
          ),
          Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _colorRow(AppLocalizations l10n) {
    final AppSurfaces s = AppSurfaces.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppScale.space16, AppScale.space12,
          AppScale.space16, AppScale.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.textColor, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppScale.space12),
          Wrap(
            spacing: AppScale.buttonGap,
            runSpacing: AppScale.space12,
            children: [
              // The theme's own ink leads, so the row has a selected swatch
              // before the user has touched anything.
              for (final color in [s.ink, ..._textColorOptions])
                _swatch(color, s),
              _colorPickerSwatch(l10n, s),
            ],
          ),
        ],
      ),
    );
  }

  Widget _swatch(Color color, AppSurfaces s) {
    final bool selected = color.toARGB32() == _ink.toARGB32();

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: () => setState(() => _textColor = color),
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: AppScale.durMicro,
          curve: AppScale.easeOut,
          width: AppScale.control,
          height: AppScale.control,
          padding: EdgeInsets.all(selected ? AppScale.ruleBar : AppScale.ruleHair),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? s.accent : s.rule,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
      ),
    );
  }

  Widget _colorPickerSwatch(AppLocalizations l10n, AppSurfaces s) {
    return Semantics(
      button: true,
      label: l10n.chooseTextColor,
      child: Tooltip(
        message: l10n.chooseTextColor,
        child: InkWell(
          onTap: () => _showCustomColorPicker(context),
          customBorder: const CircleBorder(),
          child: Container(
            width: AppScale.control,
            height: AppScale.control,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: s.paper,
              border: Border.all(color: s.ruleFirm),
            ),
            child: Icon(Icons.tune_rounded,
                size: AppScale.iconMd, color: s.accent),
          ),
        ),
      ),
    );
  }

  Widget _fontRow(AppLocalizations l10n) {
    final AppSurfaces s = AppSurfaces.of(context);
    final TextTheme type = Theme.of(context).textTheme;
    final List<String> fonts = fontController.availableFonts;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppScale.space16, AppScale.space12,
          AppScale.space16, AppScale.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.fontFamily, style: type.titleSmall),
          const SizedBox(height: AppScale.space12),
          SizedBox(
            height: AppScale.hitTarget,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: fonts.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppScale.space8),
              itemBuilder: (context, i) {
                final font = fonts[i];
                final bool selected = font == _fontFamily;
                return ChoiceChip(
                  label: Text(font),
                  selected: selected,
                  onSelected: (_) => setState(() => _fontFamily = font),
                  // Each choice shows itself in its own face.
                  labelStyle: fontController.getFontStyle(
                      font,
                      type.labelMedium
                          ?.copyWith(color: selected ? s.accent : s.ink)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context, AppLocalizations l10n) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppScale.gutter, AppScale.space8,
            AppScale.gutter, AppScale.space16),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppScale.workMeasure),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSharing ? null : _copyShareText,
                    icon: const Icon(Icons.copy_rounded,
                        size: AppScale.iconMd),
                    label: Text(l10n.copy),
                  ),
                ),
                const SizedBox(width: AppScale.buttonGap),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _isSharing ? null : _shareAsImage,
                    icon: _isSharing
                        ? const SizedBox(
                            width: AppScale.iconMd,
                            height: AppScale.iconMd,
                            child: CircularProgressIndicator(
                                strokeWidth: AppScale.ruleBar),
                          )
                        : const Icon(Icons.share_rounded,
                            size: AppScale.iconMd),
                    label: Text(_isSharing ? l10n.preparing : l10n.share),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────────
  Future<void> _copyShareText() async {
    await Clipboard.setData(ClipboardData(text: widget.data.shareText));
    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    final AppSurfaces s = AppSurfaces.of(context);
    Get.snackbar(
      l10n.copied,
      l10n.passageTextCopied,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: s.accent,
      colorText: s.onAccent,
      margin: const EdgeInsets.all(AppScale.space16),
      borderRadius: AppScale.radiusControl,
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
          margin: const EdgeInsets.all(AppScale.space16),
          borderRadius: AppScale.radiusControl,
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
          margin: const EdgeInsets.all(AppScale.space16),
          borderRadius: AppScale.radiusControl,
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _showCustomColorPicker(BuildContext context) async {
    final pickedColor = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        var tempColor = _ink;
        final l10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(l10n.chooseTextColor),
          content: SingleChildScrollView(
            child: MaterialPicker(
              pickerColor: tempColor,
              onColorChanged: (c) => tempColor = c,
              enableLabel: true,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(tempColor),
              child: Text(l10n.apply),
            ),
          ],
        );
      },
    );

    if (pickedColor != null && mounted) {
      setState(() => _textColor = pickedColor);
    }
  }
}

/// One choice in the background strip: a thumbnail of the art it applies, its
/// name under it, and the accent ring when it is the one in use.
class _StudioTile extends StatelessWidget {
  const _StudioTile({
    required this.label,
    required this.preview,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Widget preview;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppSurfaces s = AppSurfaces.of(context);

    return SizedBox(
      width: AppScale.swatch,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppScale.radiusRow),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: AppScale.durMicro,
                curve: AppScale.easeOut,
                height: AppScale.swatchTall,
                padding: EdgeInsets.all(
                    selected ? AppScale.ruleBar : AppScale.ruleHair),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppScale.radiusRow),
                  border: Border.all(
                    color: selected ? s.accent : s.rule,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppScale.radiusControl),
                  child: preview,
                ),
              ),
              const SizedBox(height: AppScale.space4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: selected ? s.accent : s.muted),
              ),
            ],
          ),
        ),
      ),
    );
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
