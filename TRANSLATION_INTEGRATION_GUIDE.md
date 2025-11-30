# Translation Integration Guide

This guide explains how to properly integrate the new translation functionality using Google ML Kit and localization into the Fihirana app.

## Overview

The translation system consists of:
- **TranslationService**: Handles Google ML Kit translation
- **LanguageDetectionService**: Detects source language automatically
- **TranslationController**: Manages translation state and caching
- **UI Components**: Ready-to-use translation widgets

## Setup Instructions

### 1. Initialize Translation Controller

In your main app or relevant screen, initialize the translation controller:

```dart
import 'package:provider/provider.dart';
import '../controller/translation_controller.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TranslationController(),
      child: MaterialApp(
        // ... your app configuration
      ),
    );
  }
}

// In your screen's initState
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final translationController = context.read<TranslationController>();
    translationController.initialize(Localizations.localeOf(context).languageCode);
  });
}
```

### 2. Add Translation Toggle

Add the translation toggle widget to your settings screen:

```dart
import '../widgets/common/translation_toggle_widget.dart';

// In your settings screen
const TranslationToggleWidget(),
```

### 3. Use Translated Text Widgets

Replace regular Text widgets with TranslatedTextWidget for automatic translation:

```dart
import '../widgets/common/translated_text_widget.dart';

// Instead of
Text('Jesosy Famonjena Fahamarinantsika'),

// Use
const TranslatedTextWidget(
  text: 'Jesosy Famonjena Fahamarinantsika',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
),

// Or for simple cases
const SimpleTranslatedText(
  'Voateny ho an\'ny fiderana',
  style: TextStyle(fontSize: 14),
),
```

### 4. Add Language Selector

Allow users to select their preferred translation language:

```dart
import '../widgets/common/language_selector_widget.dart';

// Language selector button
LanguageSelectorButton(
  currentLanguage: currentLanguage,
  onLanguageSelected: (language) {
    final translationController = context.read<TranslationController>();
    translationController.updateLocale(language);
  },
),

// Or show as dialog
showDialog(
  context: context,
  builder: (context) => LanguageSelectorDialog(
    currentLanguage: currentLanguage,
    onLanguageSelected: (language) {
      final translationController = context.read<TranslationController>();
      translationController.updateLocale(language);
      Navigator.of(context).pop();
    },
  ),
),
```

## Integration Points

### Hymn Detail Screen

In the hymn detail screen, translate hymn titles and content:

```dart
// Hymn title
TranslatedTextWidget(
  text: hymn.title,
  style: Theme.of(context).textTheme.headlineSmall,
),

// Hymn verses
Column(
  children: hymn.verses.map((verse) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TranslatedTextWidget(
        text: verse.content,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }).toList(),
),
```

### Search Screen

Translate search hints and results:

```dart
// Search hint
TextField(
  decoration: InputDecoration(
    hintText: context.watch<TranslationController>().autoTranslate
        ? 'Search hymns (auto-translate enabled)'
        : 'Search hymns',
  ),
),

// Search results
ListView.builder(
  itemCount: results.length,
  itemBuilder: (context, index) {
    final hymn = results[index];
    return ListTile(
      title: TranslatedTextWidget(
        text: hymn.title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: SimpleTranslatedText('Hymn ${hymn.number}'),
    );
  },
),
```

### Settings Screen

Add translation settings section:

```dart
Card(
  child: Column(
    children: [
      const TranslationToggleWidget(),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.language),
        title: const Text('Translation Language'),
        subtitle: Consumer<TranslationController>(
          builder: (context, controller, child) {
            return Text(controller.getLanguageName(controller.currentLocale));
          },
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => LanguageSelectorDialog(
              currentLanguage: context.read<TranslationController>().currentLocale,
              onLanguageSelected: (language) {
                context.read<TranslationController>().updateLocale(language);
                Navigator.of(context).pop();
              },
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.clear_all),
        title: const Text('Clear Translation Cache'),
        onTap: () {
          context.read<TranslationController>().clearCache();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Translation cache cleared')),
          );
        },
      ),
    ],
  ),
),
```

## Best Practices

### 1. Performance Optimization

- Use caching to avoid re-translating the same text
- Initialize translation service early in app lifecycle
- Use SimpleTranslatedText for static content that doesn't need indicators

### 2. User Experience

- Show loading indicators during translation
- Provide fallback to original text if translation fails
- Allow users to toggle auto-translation on/off
- Show translation status indicators

### 3. Error Handling

- Always handle translation errors gracefully
- Provide meaningful error messages
- Allow retry functionality for failed translations

### 4. Memory Management

- Dispose translation controller properly
- Clear cache when needed
- Monitor memory usage with large translation datasets

## Testing

Run the translation tests to ensure everything works correctly:

```bash
flutter test test/translation_test.dart
```

## Troubleshooting

### Common Issues

1. **Translation not working**: Ensure Google ML Kit is properly initialized
2. **Language detection failing**: Check if text is long enough for detection
3. **Performance issues**: Clear cache periodically and monitor memory usage
4. **UI not updating**: Ensure proper use of Consumer/Selector widgets

### Debug Tips

- Use translation statistics to monitor performance
- Check console logs for translation errors
- Test with different language combinations
- Verify network connectivity for initial model downloads

## Future Enhancements

1. **Offline translation**: Pre-download translation models
2. **Custom translation models**: Add support for domain-specific translations
3. **Translation history**: Keep track of user translations
4. **Batch translation**: Improve performance for multiple texts
5. **Translation quality scoring**: Add confidence indicators

## Support

For issues or questions about the translation system, refer to:
- Google ML Kit documentation
- Flutter localization best practices
- The example implementation in `lib/screen/translation_example_screen.dart`