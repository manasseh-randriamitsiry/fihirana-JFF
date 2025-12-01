import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/translation_controller.dart';
import '../widgets/common/translation_toggle_widget.dart';
import '../widgets/common/language_selector_widget.dart';
import '../widgets/common/translated_text_widget.dart';
import '../l10n/app_localizations.dart';

/// Example screen showing how to use the translation functionality
class TranslationExampleScreen extends StatefulWidget {
  const TranslationExampleScreen({super.key});

  @override
  State<TranslationExampleScreen> createState() => _TranslationExampleScreenState();
}

class _TranslationExampleScreenState extends State<TranslationExampleScreen> {
  final TextEditingController _textController = TextEditingController();

  String _selectedTargetLanguage = 'en';

  @override
  void initState() {
    super.initState();
    // Initialize translation controller with current locale
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final translationController = context.read<TranslationController>();
      translationController.initialize(Localizations.localeOf(context).languageCode);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translationSettings),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showTranslationStats(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Translation toggle
            const TranslationToggleWidget(),
            const SizedBox(height: 16),

            // Language selection
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.selectTranslationLanguage,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: LanguageSelectorButton(
                            currentLanguage: _selectedTargetLanguage,
                            onLanguageSelected: (language) {
                              setState(() {
                                _selectedTargetLanguage = language;
                              });
                              final translationController = context.read<TranslationController>();
                              translationController.updateLocale(language);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Manual translation test
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Translation',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        labelText: 'Enter text to translate',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Consumer<TranslationController>(
                      builder: (context, translationController, child) {
                        return ElevatedButton.icon(
                          onPressed: translationController.isTranslating
                              ? null
                              : () async {
                                  if (_textController.text.trim().isNotEmpty) {
                                    await translationController.translateText(
                                      _textController.text,
                                      targetLanguage: _selectedTargetLanguage,
                                    );
                                  }
                                },
                          icon: translationController.isTranslating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.translate),
                          label: Text(translationController.isTranslating
                              ? 'Translating...'
                              : 'Translate'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Example translated texts
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Example Translated Texts',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    const TranslatedTextWidget(
                      text: 'Jesosy Famonjena Fahamarinantsika',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    const TranslatedTextWidget(
                      text: 'Voateny ho an\'ny fiderana',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    const TranslatedTextWidget(
                      text: 'Hira 1 - Mankasitraka',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Cache management
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cache Management',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.read<TranslationController>().clearCache();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Translation cache cleared')),
                              );
                            },
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear Cache'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTranslationStats(BuildContext context) {
    final translationController = context.read<TranslationController>();
    final stats = translationController.getTranslationStats();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Translation Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cache Size: ${stats['cacheSize']}'),
            Text('Currently Translating: ${stats['currentlyTranslating']}'),
            Text('Auto-Translate: ${stats['autoTranslateEnabled'] ? 'Enabled' : 'Disabled'}'),
            Text('Current Locale: ${stats['currentLocale']}'),
            const SizedBox(height: 8),
            const Text('Supported Languages:'),
            ...stats['supportedLanguages'].map<Widget>((lang) => Text('• $lang')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}