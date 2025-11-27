import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import '../../controller/language_controller.dart';
import 'splash_widgets.dart';

class LanguageSelectionWidget extends StatefulWidget {
  final LanguageController languageController;
  final Locale? selectedLocale;
  final Function(Locale) onLanguageSelected;

  const LanguageSelectionWidget({
    super.key,
    required this.languageController,
    required this.selectedLocale,
    required this.onLanguageSelected,
  });

  @override
  State<LanguageSelectionWidget> createState() => _LanguageSelectionWidgetState();
}

class _LanguageSelectionWidgetState extends State<LanguageSelectionWidget> {
  @override
  Widget build(BuildContext context) {
    
    return IntroCardWidget(
      color: Colors.white.withValues(alpha: 0.95),
      child: Column(
        children: [
          for (final locale in widget.languageController.supportedLocales)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  widget.onLanguageSelected(locale);
                  widget.languageController.changeLanguage(locale);
                  await Future.delayed(const Duration(milliseconds: 300));
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.selectedLocale?.languageCode == locale.languageCode
                        ? Colors.orange.shade100
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.selectedLocale?.languageCode == locale.languageCode
                          ? Colors.orange.shade300
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        widget.languageController.getLanguageFlag(locale),
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.languageController.getLanguageName(locale),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: widget.selectedLocale?.languageCode ==
                                    locale.languageCode
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: widget.selectedLocale?.languageCode ==
                                    locale.languageCode
                                ? Colors.orange.shade800
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (widget.selectedLocale?.languageCode == locale.languageCode)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}