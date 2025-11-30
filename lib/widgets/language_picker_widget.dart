import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/language_controller.dart';

import 'common/mlkit_localization_provider.dart';

class LanguagePickerWidget extends StatelessWidget {
  const LanguagePickerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final LanguageController languageController =
        Get.find<LanguageController>();

    return Obx(() {
      // Access the observable directly to ensure proper tracking
      languageController.currentLocale.value;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).hintColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.language,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  context.translateWithMLKit((l) => l.language),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...languageController.supportedLocales.map((locale) {
              final isSelected = languageController.isCurrentLocale(locale);
              final languageName = languageController.getLanguageName(locale);
              final languageFlag = languageController.getLanguageFlag(locale);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => languageController.changeLanguage(locale),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.1)
                            : Theme.of(context).cardColor,
                      ),
                      child: Row(
                        children: [
                          Text(
                            languageFlag,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              languageName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color,
                                  ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

class LanguagePickerDialog extends StatefulWidget {
  const LanguagePickerDialog({super.key});

  @override
  State<LanguagePickerDialog> createState() => _LanguagePickerDialogState();
}

class _LanguagePickerDialogState extends State<LanguagePickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  final LanguageController _languageController = Get.find<LanguageController>();
  List<Locale> _filteredLocales = [];

  @override
  void initState() {
    super.initState();
    _filteredLocales = _languageController.supportedLocales;
    _searchController.addListener(_filterLanguages);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLanguages() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredLocales = _languageController.supportedLocales;
      } else {
        _filteredLocales = _languageController.supportedLocales.where((locale) {
          final name =
              _languageController.getLanguageName(locale).toLowerCase();
          final code = locale.languageCode.toLowerCase();
          return name.contains(query) || code.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.translateWithMLKit((l) => l.chooseLanguage),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search language...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredLocales.length,
                itemBuilder: (context, index) {
                  final locale = _filteredLocales[index];
                  final isSelected =
                      _languageController.isCurrentLocale(locale);
                  final languageName =
                      _languageController.getLanguageName(locale);
                  final languageFlag =
                      _languageController.getLanguageFlag(locale);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Text(
                        languageFlag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        languageName,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).primaryColor,
                            )
                          : null,
                      onTap: () {
                        _languageController.changeLanguage(locale);
                        Navigator.of(context).pop();
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              child: Text(context.translateWithMLKit((l) => l.cancel)),
            ),
          ],
        ),
      ),
    );
  }
}

class LanguagePickerButton extends StatelessWidget {
  const LanguagePickerButton({super.key});

  @override
  Widget build(BuildContext context) {
    final LanguageController languageController =
        Get.find<LanguageController>();

    return Obx(() {
      final currentLocale = languageController.currentLocaleValue;
      final languageName = languageController.getLanguageName(currentLocale);
      final languageFlag = languageController.getLanguageFlag(currentLocale);

      return ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const LanguagePickerDialog(),
          );
        },
        icon: Text(languageFlag),
        label: Text(languageName),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    });
  }
}
