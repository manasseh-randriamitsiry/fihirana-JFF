import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/language_controller.dart';
import '../controller/color_controller.dart';
import '../l10n/app_localizations.dart';

class SimpleLanguagePickerDialog extends StatelessWidget {
  const SimpleLanguagePickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageController = Get.find<LanguageController>();
    final colorController = Get.find<ColorController>();

    return Dialog(
      backgroundColor: colorController.backgroundColor.value,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              size: 60,
              color: colorController.primaryColor.value,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.chooseLanguage,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colorController.textColor.value,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Language options without search
            ...languageController.supportedLocales.map((locale) {
              final isSelected = languageController.isCurrentLocale(locale);
              final languageName = languageController.getLanguageName(locale);
              final languageFlag = languageController.getLanguageFlag(locale);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    languageController.changeLanguage(locale);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorController.primaryColor.value.withValues(alpha: 0.1)
                          : colorController.backgroundColor.value,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? colorController.primaryColor.value
                            : colorController.textColor.value.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          languageFlag,
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            languageName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected
                                  ? colorController.primaryColor.value
                                  : colorController.textColor.value,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colorController.primaryColor.value,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: colorController.textColor.value,
              ),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      ),
    );
  }
}