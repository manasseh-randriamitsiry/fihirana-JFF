import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/font_controller.dart';
import '../../l10n/app_localizations.dart';

class FontSelectionPage extends StatefulWidget {
  const FontSelectionPage({super.key});

  @override
  FontSelectionPageState createState() => FontSelectionPageState();
}

class FontSelectionPageState extends State<FontSelectionPage> {
  final FontController fontController = Get.find<FontController>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.chooseFont),
      ),
      body: Obx(() {
        final currentFont = fontController.currentFont.value;
        final fonts = fontController.availableFonts;

        return ListView.builder(
          itemCount: fonts.length,
          itemBuilder: (context, index) {
            final fontName = fonts[index];
            final isSelected = fontName == currentFont;

            return ListTile(
              title: Text(
                fontName,
                style: fontController.getFontStyle(
                    fontName, const TextStyle(fontSize: 16)),
              ),
              trailing: isSelected
                  ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                  : null,
              onTap: () {
                fontController.changeFont(fontName);
                Navigator.pop(context, fontName);
              },
            );
          },
        );
      }),
    );
  }
}
