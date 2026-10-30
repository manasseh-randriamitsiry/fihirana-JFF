import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fihirana/app/theme/font_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/design_system/app_scale.dart';

class FontPickerWidget extends StatelessWidget {
  final FontController _fontController = Get.find<FontController>();

  FontPickerWidget({super.key});

  // Method to show the font picker as a bottom sheet
  static void showFontPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FontPickerWidget();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GetBuilder<ColorController>(
      builder: (colorController) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: colorController.backgroundColor.value,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppScale.radiusFloat)),
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
                margin: const EdgeInsets.only(
                    top: AppScale.space12, bottom: AppScale.space8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      colorController.primaryColor.value.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppScale.radiusMark),
                ),
              ),
            ),
            // Title and Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(AppScale.gutter,
                  AppScale.space8, AppScale.gutter, AppScale.space16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.font_download,
                        size: 28,
                        color: colorController.primaryColor.value,
                      ),
                      const SizedBox(width: AppScale.space12),
                      Text(
                        l10n.chooseFontStyle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorController.textColor.value,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          const url = 'https://fonts.google.com/';
                          try {
                            final uri = Uri.parse(url);
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          } catch (e) {
                            Get.snackbar(
                              'Erreur',
                              'Impossible d\'ouvrir Google Fonts',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        },
                        icon: Icon(
                          Icons.help_outline,
                          color: colorController.primaryColor.value,
                          size: 24,
                        ),
                        tooltip: 'Télécharger des polices sur Google Fonts',
                      ),
                      const SizedBox(width: AppScale.space8),
                      IconButton(
                        onPressed: () async {
                          await _fontController.importFont();
                          // Rebuild to show the new font in the list
                          if (context.mounted) {
                            (context as Element).markNeedsBuild();
                          }
                        },
                        icon: Icon(
                          Icons.add,
                          color: colorController.primaryColor.value,
                          size: 28,
                        ),
                        tooltip: 'Importer une police',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Font List
            Expanded(
              child: ListView.builder(
                key: const PageStorageKey('fonts_list'),
                padding: EdgeInsets.fromLTRB(
                    AppScale.gutter,
                    0,
                    AppScale.gutter,
                    AppScale.space16 + MediaQuery.paddingOf(context).bottom),
                itemCount: _fontController.availableFonts.length,
                itemBuilder: (context, index) {
                  final fontName = _fontController.availableFonts[index];
                  return Obx(() {
                    final isSelected =
                        _fontController.currentFont.value == fontName;
                    return Container(
                      key: ValueKey(fontName),
                      margin: const EdgeInsets.only(bottom: AppScale.space12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorController.primaryColor.value
                                .withValues(alpha: 0.1)
                            : colorController.backgroundColor.value,
                        borderRadius: BorderRadius.circular(AppScale.radiusRow),
                        border: Border.all(
                          color: isSelected
                              ? colorController.primaryColor.value
                              : colorController.textColor.value
                                  .withValues(alpha: 0.1),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: colorController.primaryColor.value
                                  .withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(AppScale.radiusRow),
                          onTap: () {
                            _fontController.changeFont(fontName);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(AppScale.space16),
                            child: Row(
                              children: [
                                // Radio indicator
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? colorController.primaryColor.value
                                          : colorController.textColor.value
                                              .withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                    color: isSelected
                                        ? colorController.primaryColor.value
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: AppScale.space16),
                                // Font info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fontName,
                                        style: TextStyle(
                                          color:
                                              colorController.textColor.value,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: AppScale.space4),
                                      Text(
                                        l10n.sampleText,
                                        style: _fontController.getFontStyle(
                                          fontName,
                                          TextStyle(
                                            color: colorController
                                                .textColor.value
                                                .withValues(alpha: 0.8),
                                            fontSize: 16,
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
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
