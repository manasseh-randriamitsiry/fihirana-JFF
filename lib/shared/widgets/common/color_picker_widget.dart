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
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ColorPickerWidget();
      },
    );
  }

  void _showColorPicker(BuildContext context, String colorType,
      Color currentColor, Function(Color) onColorChanged) {
    final l10n = AppLocalizations.of(context);
    final colorController = Get.find<ColorController>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: colorController.backgroundColor.value,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorController.primaryColor.value,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chooseColorFor(colorType),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorController.textColor.value,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    child: MaterialPicker(
                      pickerColor: currentColor,
                      onColorChanged: (color) {
                        // Validate the color change
                        final validationError =
                            ColorValidation.validateColorChange(
                          colorType,
                          color,
                          colorController,
                        );
                        if (validationError != null) {
                          Get.snackbar(
                            'Erreur de validation',
                            validationError,
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 4),
                          );
                          // Don't apply the color change
                          return;
                        }
                        // Apply the color change if validation passes
                        onColorChanged(color);
                      },
                      enableLabel: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          l10n.accept,
                          style: TextStyle(
                            color: colorController.primaryColor.value,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _pickIconColor(BuildContext context, ColorController controller) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: controller.backgroundColor.value,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: controller.primaryColor.value,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chooseColor,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: controller.textColor.value,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  child: BlockPicker(
                    pickerColor: controller.iconColor.value,
                    onColorChanged: (color) async {
                      await controller.updateIconColor(color);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.ok,
                        style: TextStyle(
                          color: controller.primaryColor.value,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pickDrawerColor(BuildContext context, ColorController controller) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: controller.backgroundColor.value,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: controller.primaryColor.value,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.drawerColor,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: controller.textColor.value,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  child: BlockPicker(
                    pickerColor: controller.drawerColor.value,
                    onColorChanged: (color) {
                      // Validate the color change
                      final validationError =
                          ColorValidation.validateColorChange(
                        'drawer',
                        color,
                        controller,
                      );
                      if (validationError != null) {
                        Get.snackbar(
                          'Erreur de validation',
                          validationError,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                          duration: const Duration(seconds: 4),
                        );
                        // Don't apply the color change
                        return;
                      }
                      // Apply the color change if validation passes
                      controller.updateDrawerColor(color);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        l10n.ok,
                        style: TextStyle(
                          color: controller.primaryColor.value,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton(
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 12.0, horizontal: AppDimensions.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorController.textColor.value,
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      colorController.primaryColor.value.withValues(alpha: 0.3),
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

  Widget _buildPresetSchemes() {
    final l10n = AppLocalizations.of(Get.context!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Text(
            l10n.presetColors,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorController.textColor.value,
            ),
          ),
        ),
        SizedBox(
          height: 140,
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
                  width: 110,
                  margin:
                      const EdgeInsets.symmetric(horizontal: AppDimensions.xs),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white12,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.1),
                        blurRadius: isSelected ? 12 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
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
                      const SizedBox(height: 8),
                      Text(
                        scheme['name'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: Colors.white,
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

    return GetBuilder<ColorController>(
      builder: (colorController) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: colorController.backgroundColor.value,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(
              color: colorController.primaryColor.value,
              width: 2,
            ),
            left: BorderSide(
              color: colorController.primaryColor.value,
              width: 2,
            ),
            right: BorderSide(
              color: colorController.primaryColor.value,
              width: 2,
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
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      colorController.primaryColor.value.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.color_lens,
                    size: 28,
                    color: colorController.primaryColor.value,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.chooseColor,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorController.textColor.value,
                    ),
                  ),
                ],
              ),
            ),
            // Preset schemes (horizontal scroll)
            _buildPresetSchemes(),
            const SizedBox(height: 16),
            // Divider
            const Divider(
              color: Colors.white12,
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: 8),
            // Custom colors section
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 12.0),
                      child: Text(
                        l10n.customColors,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorController.textColor.value,
                        ),
                      ),
                    ),
                    _buildColorButton(
                      l10n.primaryColor,
                      colorController.primaryColor.value,
                      () => _showColorPicker(
                        context,
                        'fototra',
                        colorController.primaryColor.value,
                        (color) async =>
                            await colorController.updateColors(primary: color),
                      ),
                    ),
                    _buildColorButton(
                      l10n.textColor,
                      colorController.textColor.value,
                      () => _showColorPicker(
                        context,
                        'soratra',
                        colorController.textColor.value,
                        (color) async =>
                            await colorController.updateColors(text: color),
                      ),
                    ),
                    _buildColorButton(
                      l10n.backgroundColor,
                      colorController.backgroundColor.value,
                      () => _showColorPicker(
                        context,
                        'ambadika',
                        colorController.backgroundColor.value,
                        (color) async => await colorController.updateColors(
                            background: color),
                      ),
                    ),
                    _buildColorButton(
                      l10n.drawerColor,
                      colorController.drawerColor.value,
                      () => _pickDrawerColor(context, colorController),
                    ),
                    _buildColorButton(
                      l10n.iconColor,
                      colorController.iconColor.value,
                      () => _pickIconColor(context, colorController),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
