import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';

class ColorValidation {
  static String? validateColorChange(
    String colorType,
    Color newColor,
    ColorController controller,
  ) {
    // Check for same color conflicts that would make text invisible
    switch (colorType) {
      case 'fototra': // primary
        if (newColor == controller.textColor.value) {
          return 'La couleur primaire ne peut pas être identique à la couleur du texte, sinon le texte sera invisible.';
        }
        break;
      case 'soratra': // text
        if (newColor == controller.primaryColor.value) {
          return 'La couleur du texte ne peut pas être identique à la couleur primaire, sinon le texte sera invisible.';
        }
        if (newColor == controller.drawerColor.value) {
          return 'La couleur du texte ne peut pas être identique à la couleur du tiroir, sinon le texte sera invisible.';
        }
        if (newColor == controller.backgroundColor.value) {
          return 'La couleur du texte ne peut pas être identique à la couleur d\'arrière-plan, sinon le texte sera invisible.';
        }
        break;
      case 'ambadika': // background
        if (newColor == controller.textColor.value) {
          return 'La couleur d\'arrière-plan ne peut pas être identique à la couleur du texte, sinon le texte sera invisible.';
        }
        break;
    }

    // Additional validation for drawer color
    if (colorType == 'drawer' && newColor == controller.textColor.value) {
      return 'La couleur du tiroir ne peut pas être identique à la couleur du texte, sinon le texte sera invisible.';
    }

    return null; // No validation error
  }
}

class ColorPickerWidget extends StatelessWidget {
  final ColorController colorController = Get.find<ColorController>();

  ColorPickerWidget({super.key});

  // Method to show the color picker as a bottom sheet
  static void showColorPickerDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ColorPickerWidget();
      },
    );
  }

  void _showColorPicker(
    BuildContext context,
    String colorType,
    Color currentColor,
    ValueChanged<Color> onColorChanged,
  ) {
    final l10n = AppLocalizations.of(context);
    final colorController = Get.find<ColorController>();
    _showPaletteDialog(
      context: context,
      title: l10n.chooseColorFor(colorType),
      pickerColor: currentColor,
      confirmLabel: l10n.accept,
      onColorChanged: (color) {
        final validationError = ColorValidation.validateColorChange(
          colorType,
          color,
          colorController,
        );
        if (validationError != null) {
          _showValidationError(context, validationError);
          return;
        }
        onColorChanged(color);
      },
    );
  }

  void _pickIconColor(BuildContext context, ColorController controller) {
    final l10n = AppLocalizations.of(context);
    _showPaletteDialog(
      context: context,
      title: l10n.chooseColor,
      pickerColor: controller.iconColor.value,
      confirmLabel: l10n.ok,
      onColorChanged: controller.updateIconColor,
    );
  }

  void _pickDrawerColor(BuildContext context, ColorController controller) {
    final l10n = AppLocalizations.of(context);
    _showPaletteDialog(
      context: context,
      title: l10n.drawerColor,
      pickerColor: controller.drawerColor.value,
      confirmLabel: l10n.ok,
      onColorChanged: (color) {
        final validationError = ColorValidation.validateColorChange(
          'drawer',
          color,
          controller,
        );
        if (validationError != null) {
          _showValidationError(context, validationError);
          return;
        }
        controller.updateDrawerColor(color);
      },
    );
  }

  void _showPaletteDialog({
    required BuildContext context,
    required String title,
    required Color pickerColor,
    required String confirmLabel,
    required ValueChanged<Color> onColorChanged,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        final colorScheme = Theme.of(dialogContext).colorScheme;
        final isCompact = size.width < 360 || size.height < 640;

        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 440,
              maxHeight: size.height * .84,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isCompact ? 14 : 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(dialogContext).textTheme.titleLarge,
                    ),
                    SizedBox(height: isCompact ? 12 : 16),
                    _buildAdaptivePalette(
                      context: dialogContext,
                      pickerColor: pickerColor,
                      onColorChanged: onColorChanged,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(confirmLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdaptivePalette({
    required BuildContext context,
    required Color pickerColor,
    required ValueChanged<Color> onColorChanged,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colorScheme = Theme.of(context).colorScheme;
        final isCompact = constraints.maxWidth < 330;
        final columnCount = isCompact ? 4 : 5;
        final spacing = isCompact ? 6.0 : 8.0;
        final itemSize =
            (constraints.maxWidth - (spacing * (columnCount - 1))) /
                columnCount;

        return BlockPicker(
          pickerColor: pickerColor,
          onColorChanged: onColorChanged,
          useInShowDialog: false,
          layoutBuilder: (context, colors, child) => Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final color in colors)
                SizedBox(
                    width: itemSize, height: itemSize, child: child(color)),
            ],
          ),
          itemBuilder: (color, isSelected, selectColor) => Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: selectColor,
              customBorder: const CircleBorder(),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.onSurface
                        : colorScheme.outlineVariant.withValues(alpha: .55),
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: ThemeData.estimateBrightnessForColor(color) ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      )
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showValidationError(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    Get.snackbar(
      'Erreur de validation',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: colorScheme.errorContainer,
      colorText: colorScheme.onErrorContainer,
      duration: const Duration(seconds: 4),
    );
  }

  Widget _buildColorButton(
    BuildContext context,
    String label,
    Color color,
    VoidCallback onTap, {
    bool compact = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = TextStyle(
      fontSize: compact ? 14 : 16,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: compact ? 8 : 12,
          horizontal: AppDimensions.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: compact ? 34 : 40,
              height: compact ? 34 : 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetSchemes(BuildContext context, {required bool compact}) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final cardWidth = compact ? 96.0 : 110.0;
    final previewSize = compact ? 56.0 : 70.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: compact ? 8 : 12,
          ),
          child: Text(
            l10n.presetColors,
            style: TextStyle(
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: compact ? 112 : 140,
          child: ListView.builder(
            key: const PageStorageKey('color_schemes_list'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md),
            itemCount: colorController.colorSchemes.length,
            itemBuilder: (context, index) {
              final scheme = colorController.colorSchemes[index];
              final isSelected =
                  colorController.currentSchemeIndex.value == index;

              return GestureDetector(
                key: ValueKey(index),
                onTap: () async => await colorController.setColorScheme(index),
                child: Container(
                  width: cardWidth,
                  margin:
                      const EdgeInsets.symmetric(horizontal: AppDimensions.xs),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.22)
                            : colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: isSelected ? 12 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: previewSize,
                        height: previewSize,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              scheme['primary'] as Color,
                              scheme['accent'] as Color,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (scheme['primary'] as Color)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: compact ? 6 : 8),
                      Text(
                        scheme['name'] as String,
                        style: TextStyle(
                          fontSize: compact ? 11 : 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;
    final isCompact = mediaQuery.size.width < 360 || availableHeight < 600;
    final sheetHeight = (availableHeight * (isCompact ? .90 : .82))
        .clamp(360.0, 680.0)
        .toDouble();
    final colorScheme = Theme.of(context).colorScheme;

    return GetBuilder<ColorController>(
      builder: (colorController) => SizedBox(
        height: sheetHeight,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
              left: BorderSide(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
              right: BorderSide(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: isCompact ? 8 : 12, bottom: 8),
                  width: isCompact ? 32 : 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Title
              Padding(
                padding: EdgeInsets.fromLTRB(
                    AppDimensions.md, 8, AppDimensions.md, isCompact ? 8 : 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.color_lens,
                      size: 28,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.chooseColor,
                        style: TextStyle(
                          fontSize: isCompact ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Preset schemes (horizontal scroll)
              _buildPresetSchemes(context, compact: isCompact),
              SizedBox(height: isCompact ? 8 : 16),
              // Divider
              Divider(
                color: colorScheme.outlineVariant,
                thickness: 1,
                height: 1,
              ),
              SizedBox(height: isCompact ? 4 : 8),
              // Custom colors section
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDimensions.md,
                          vertical: isCompact ? 8 : 12,
                        ),
                        child: Text(
                          l10n.customColors,
                          style: TextStyle(
                            fontSize: isCompact ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      _buildColorButton(
                        context,
                        l10n.primaryColor,
                        colorController.primaryColor.value,
                        () => _showColorPicker(
                          context,
                          'fototra',
                          colorController.primaryColor.value,
                          (color) async => await colorController.updateColors(
                              primary: color),
                        ),
                        compact: isCompact,
                      ),
                      _buildColorButton(
                        context,
                        l10n.textColor,
                        colorController.textColor.value,
                        () => _showColorPicker(
                          context,
                          'soratra',
                          colorController.textColor.value,
                          (color) async =>
                              await colorController.updateColors(text: color),
                        ),
                        compact: isCompact,
                      ),
                      _buildColorButton(
                        context,
                        l10n.backgroundColor,
                        colorController.backgroundColor.value,
                        () => _showColorPicker(
                          context,
                          'ambadika',
                          colorController.backgroundColor.value,
                          (color) async => await colorController.updateColors(
                              background: color),
                        ),
                        compact: isCompact,
                      ),
                      _buildColorButton(
                        context,
                        l10n.drawerColor,
                        colorController.drawerColor.value,
                        () => _pickDrawerColor(context, colorController),
                        compact: isCompact,
                      ),
                      _buildColorButton(
                        context,
                        l10n.iconColor,
                        colorController.iconColor.value,
                        () => _pickIconColor(context, colorController),
                        compact: isCompact,
                      ),
                      SizedBox(height: isCompact ? 12 : 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
