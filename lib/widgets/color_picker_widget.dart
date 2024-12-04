import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import '../controller/color_controller.dart';

class ColorPickerWidget extends StatelessWidget {
  final ColorController colorController = Get.find<ColorController>();

  ColorPickerWidget({super.key});

  void _showColorPicker(BuildContext context, String colorType,
      Color currentColor, Function(Color) onColorChanged) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colorController.backgroundColor.value,
          title: Text(
            'Misafidy loko $colorType',
            style: TextStyle(color: colorController.textColor.value),
          ),
          content: SingleChildScrollView(
            child: MaterialPicker(
              pickerColor: currentColor,
              onColorChanged: onColorChanged,
              enableLabel: true,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Ekena',
                style: TextStyle(color: colorController.primaryColor.value),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _pickIconColor(BuildContext context, ColorController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Safidio ny loko'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: controller.iconColor.value,
            onColorChanged: (color) {
              controller.iconColor.value = color;
              controller.update(['iconColor']);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          InkWell(
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSchemes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Loko efa voaomana',
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
            return InkWell(
              onTap: () => colorController.setColorScheme(index),
              child: Container(
                width: 80,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: (scheme['primary'] as Color).withOpacity(0.1),
                  border: Border.all(
                    color: colorController.currentSchemeIndex == index
                        ? (scheme['accent'] as Color)
                        : Colors.transparent,
                    width: 2,
                  ),
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
    return GetBuilder<ColorController>(
      builder: (colorController) => Card(
        color: colorController.backgroundColor.value,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Safidio ny loko tianao',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorController.textColor.value,
                ),
              ),
              const SizedBox(height: 16),
              _buildPresetSchemes(),
              const Divider(height: 32),
              Text(
                'Loko manokana',
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
                      'Loko fototra',
                      colorController.primaryColor.value,
                      () => _showColorPicker(
                        context,
                        'fototra',
                        colorController.primaryColor.value,
                        (color) => colorController.updateColors(primary: color),
                      ),
                    ),
                    _buildColorButton(
                      'Loko fanampiny',
                      colorController.accentColor.value,
                      () => _showColorPicker(
                        context,
                        'fanampiny',
                        colorController.accentColor.value,
                        (color) => colorController.updateColors(accent: color),
                      ),
                    ),
                    _buildColorButton(
                      'Loko soratra',
                      colorController.textColor.value,
                      () => _showColorPicker(
                        context,
                        'soratra',
                        colorController.textColor.value,
                        (color) => colorController.updateColors(text: color),
                      ),
                    ),
                    _buildColorButton(
                      'Loko ambadika',
                      colorController.backgroundColor.value,
                      () => _showColorPicker(
                        context,
                        'ambadika',
                        colorController.backgroundColor.value,
                        (color) => colorController.updateColors(background: color),
                      ),
                    ),
                    _buildColorButton(
                      'Loko drawer',
                      colorController.drawerColor.value,
                      () => _showColorPicker(
                        context,
                        'drawer',
                        colorController.drawerColor.value,
                        (color) => colorController.updateColors(drawer: color),
                      ),
                    ),
                    GetBuilder<ColorController>(
                      id: 'iconColor',
                      builder: (controller) => ListTile(
                        title: const Text('Loko icon'),
                        trailing: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: controller.iconColor.value,
                            border: Border.all(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        onTap: () => _pickIconColor(context, controller),
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
