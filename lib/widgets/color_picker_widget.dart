import 'package:flutter/material.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import '../controller/color_controller.dart';
import '../l10n/app_localizations.dart';

class ColorPickerWidget extends StatelessWidget {
  final ColorController colorController = Get.find<ColorController>();

  ColorPickerWidget({super.key});

  // Method to show the color picker as a dialog
  static void showColorPickerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ColorPickerWidget(),
        );
      },
    );
  }

  void _showColorPicker(BuildContext context, String colorType,
      Color currentColor, Function(Color) onColorChanged) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Neumorphic(
            style: NeumorphicStyle(
              color: colorController.backgroundColor.value,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
              depth: 6,
              intensity: 0.8,
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
                      onColorChanged: onColorChanged,
                      enableLabel: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      NeumorphicButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: NeumorphicStyle(
                          color: colorController.backgroundColor.value,
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(8)),
                          depth: 2,
                        ),
                        child: Text(
                          l10n.accept,
                          style:
                              TextStyle(color: colorController.textColor.value),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Neumorphic(
          style: NeumorphicStyle(
            color: controller.backgroundColor.value,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
            depth: 6,
            intensity: 0.8,
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
                    NeumorphicButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: NeumorphicStyle(
                        color: controller.backgroundColor.value,
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(8)),
                        depth: 2,
                      ),
                      child: Text(
                        l10n.ok,
                        style: TextStyle(color: controller.textColor.value),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Neumorphic(
          style: NeumorphicStyle(
            color: controller.backgroundColor.value,
            boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
            depth: 6,
            intensity: 0.8,
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
                      controller.updateDrawerColor(color);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    NeumorphicButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: NeumorphicStyle(
                        color: controller.backgroundColor.value,
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(8)),
                        depth: 2,
                      ),
                      child: Text(
                        l10n.ok,
                        style: TextStyle(color: controller.textColor.value),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: colorController.textColor.value,
            ),
          ),
          NeumorphicButton(
            onPressed: onTap,
            style: NeumorphicStyle(
              color: color,
              boxShape: NeumorphicBoxShape.circle(),
              depth: 2,
              intensity: 0.8,
            ),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: colorController.accentColor.value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSchemes() {
    final l10n = AppLocalizations.of(Get.context!)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            l10n.presetColors,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorController.textColor.value,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colorController.colorSchemes.asMap().entries.map((entry) {
            final index = entry.key;
            final scheme = entry.value;
            return NeumorphicButton(
              onPressed: () async =>
                  await colorController.setColorScheme(index),
              style: NeumorphicStyle(
                color: (scheme['primary'] as Color).withOpacity(0.1),
                boxShape:
                    NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                depth: colorController.currentSchemeIndex == index ? 4 : 2,
                intensity: 0.8,
              ),
              child: Container(
                width: 80,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: colorController.currentSchemeIndex == index
                      ? Border.all(
                          color: scheme['accent'] as Color,
                          width: 2,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme['primary'] as Color,
                            scheme['accent'] as Color,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scheme['name'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorController.textColor.value,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GetBuilder<ColorController>(
      builder: (colorController) => Neumorphic(
        style: NeumorphicStyle(
          color: colorController.backgroundColor.value,
          boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(15)),
          depth: 4,
          intensity: 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Neumorphic(
                style: NeumorphicStyle(
                  color: colorController.accentColor.value,
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(8)),
                  depth: 2,
                  intensity: 0.8,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    l10n.chooseColor,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorController.textColor.value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildPresetSchemes(),
              Neumorphic(
                style: NeumorphicStyle(
                  color: colorController.backgroundColor.value,
                  boxShape:
                      NeumorphicBoxShape.roundRect(BorderRadius.circular(2)),
                  depth: 1,
                  intensity: 0.5,
                ),
                child: const SizedBox(height: 32),
              ),
              Text(
                l10n.customColors,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorController.textColor.value,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
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
                    NeumorphicButton(
                      onPressed: () =>
                          _pickDrawerColor(context, colorController),
                      style: NeumorphicStyle(
                        color: colorController.backgroundColor.value,
                        boxShape: NeumorphicBoxShape.roundRect(
                            BorderRadius.circular(8)),
                        depth: 2,
                        intensity: 0.8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.drawerColor,
                              style: TextStyle(
                                  color: colorController.textColor.value),
                            ),
                            Neumorphic(
                              style: NeumorphicStyle(
                                color: colorController.drawerColor.value,
                                boxShape: NeumorphicBoxShape.circle(),
                                depth: 2,
                              ),
                              child: Container(
                                width: 30,
                                height: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GetBuilder<ColorController>(
                      id: 'iconColor',
                      builder: (controller) => NeumorphicButton(
                        onPressed: () => _pickIconColor(context, controller),
                        style: NeumorphicStyle(
                          color: colorController.backgroundColor.value,
                          boxShape: NeumorphicBoxShape.roundRect(
                              BorderRadius.circular(8)),
                          depth: 2,
                          intensity: 0.8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.iconColor,
                                style: TextStyle(
                                    color: colorController.textColor.value),
                              ),
                              Neumorphic(
                                style: NeumorphicStyle(
                                  color: controller.iconColor.value,
                                  boxShape: NeumorphicBoxShape.circle(),
                                  depth: 2,
                                ),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
