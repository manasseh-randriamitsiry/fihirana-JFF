import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/font_controller.dart';
import '../controller/color_controller.dart';

class FontPickerWidget extends StatelessWidget {
  final FontController _fontController = Get.find<FontController>();
  final ColorController _colorController = Get.find<ColorController>();

  FontPickerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _colorController.backgroundColor.value,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Safidio ny endrika soratra tianao',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _colorController.textColor.value,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListView.builder(
                  itemCount: _fontController.availableFonts.length,
                  itemBuilder: (context, index) {
                    final fontName = _fontController.availableFonts[index];
                    return Obx(() => RadioListTile<String>(
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fontName,
                                style: TextStyle(
                                  color: _colorController.textColor.value,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Jesosy Famonjena Fahamarinantsika',
                                style: _fontController.getFontStyle(
                                  fontName,
                                  TextStyle(
                                    color: _colorController.textColor.value,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          value: fontName,
                          groupValue: _fontController.currentFont.value,
                          onChanged: (value) {
                            if (value != null) {
                              _fontController.changeFont(value);
                            }
                          },
                          activeColor: _colorController.primaryColor.value,
                        ));
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Ekena',
                    style: TextStyle(
                      color: _colorController.primaryColor.value,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
