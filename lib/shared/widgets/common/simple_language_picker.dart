import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/core/localization/language_controller.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'localization_extension.dart';
import 'package:fihirana/core/design_system/app_scale.dart';

class SimpleLanguagePicker extends StatelessWidget {
  const SimpleLanguagePicker({super.key});

  // Method to show the language picker as a bottom sheet
  static void showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const SimpleLanguagePicker();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return GetBuilder<ColorController>(
      builder: (colorController) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
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
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(AppScale.gutter,
                  AppScale.space8, AppScale.gutter, AppScale.space16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.language,
                    size: 28,
                    color: colorController.primaryColor.value,
                  ),
                  const SizedBox(width: AppScale.space12),
                  Text(
                    context.translate((l) => l.language),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorController.textColor.value,
                    ),
                  ),
                ],
              ),
            ),
            // Language List
            Expanded(
              child: Obx(() {
                return ListView(
                  key: const PageStorageKey('language_picker_list'),
                  // The sheet stops at the physical edge of the phone: the last
                  // option has to clear the home indicator.
                  padding: EdgeInsets.fromLTRB(
                      AppScale.gutter,
                      0,
                      AppScale.gutter,
                      AppScale.space16 + MediaQuery.paddingOf(context).bottom),
                  children: languageController.supportedLocales.map((locale) {
                    final isSelected =
                        languageController.isCurrentLocale(locale);
                    final languageName =
                        languageController.getLanguageName(locale);
                    final languageFlag =
                        languageController.getLanguageFlag(locale);

                    return Container(
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
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(AppScale.radiusRow),
                          onTap: () =>
                              languageController.changeLanguage(locale),
                          child: Padding(
                            padding: const EdgeInsets.all(AppScale.space16),
                            child: Row(
                              children: [
                                Text(
                                  languageFlag,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: AppScale.space16),
                                Expanded(
                                  child: Text(
                                    languageName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? colorController.primaryColor.value
                                          : colorController.textColor.value,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    size: 20,
                                    color: colorController.primaryColor.value,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
