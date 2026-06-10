import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/core/localization/translation_controller.dart';

class LanguageSelectorWidget extends StatelessWidget {
  final String? selectedLanguage;
  final Function(String) onLanguageSelected;
  final String? title;

  const LanguageSelectorWidget({
    super.key,
    this.selectedLanguage,
    required this.onLanguageSelected,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslationController>(
      builder: (context, translationController, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? AppLocalizations.of(context).chooseLanguage,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ...translationController.getSupportedLanguages().map(
                      (languageCode) => RadioMenuButton<String>(
                        value: languageCode,
                        groupValue: selectedLanguage ??
                            translationController.currentLocale,
                        onChanged: (value) {
                          if (value != null) {
                            onLanguageSelected(value);
                            Navigator.of(context).pop();
                          }
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all(Colors.transparent),
                          foregroundColor: WidgetStateProperty.all(
                              Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              translationController
                                  .getLanguageName(languageCode),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Text(
                              languageCode.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withValues(alpha: 0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 8),
                if (translationController.isTranslating) ...[
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Please wait while translation models load...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Dialog for language selection
class LanguageSelectorDialog extends StatelessWidget {
  final String? currentLanguage;
  final Function(String) onLanguageSelected;

  const LanguageSelectorDialog({
    super.key,
    this.currentLanguage,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400),
        child: LanguageSelectorWidget(
          selectedLanguage: currentLanguage,
          onLanguageSelected: onLanguageSelected,
          title: 'Select Translation Language',
        ),
      ),
    );
  }
}

/// Bottom sheet for language selection
class LanguageSelectorBottomSheet extends StatelessWidget {
  final String? currentLanguage;
  final Function(String) onLanguageSelected;

  const LanguageSelectorBottomSheet({
    super.key,
    this.currentLanguage,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: LanguageSelectorWidget(
              selectedLanguage: currentLanguage,
              onLanguageSelected: onLanguageSelected,
            ),
          ),
        );
      },
    );
  }
}

/// Button to show language selector
class LanguageSelectorButton extends StatelessWidget {
  final String? currentLanguage;
  final Function(String) onLanguageSelected;
  final bool useBottomSheet;

  const LanguageSelectorButton({
    super.key,
    this.currentLanguage,
    required this.onLanguageSelected,
    this.useBottomSheet = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TranslationController>(
      builder: (context, translationController, child) {
        return ElevatedButton.icon(
          onPressed: () {
            if (useBottomSheet) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => LanguageSelectorBottomSheet(
                  currentLanguage: currentLanguage,
                  onLanguageSelected: onLanguageSelected,
                ),
              );
            } else {
              showDialog(
                context: context,
                builder: (context) => LanguageSelectorDialog(
                  currentLanguage: currentLanguage,
                  onLanguageSelected: onLanguageSelected,
                ),
              );
            }
          },
          icon: const Icon(Icons.translate),
          label: Text(
            translationController.getLanguageName(
              currentLanguage ?? translationController.currentLocale,
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      },
    );
  }
}
