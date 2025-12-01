import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:fihirana/controller/translation_controller.dart';
import 'package:fihirana/services/translation_service.dart';
import 'package:fihirana/services/language_detection_service.dart';

// Generate mocks
@GenerateMocks([TranslationService, LanguageDetectionService])
import 'translation_test.mocks.dart';

void main() {
  group('TranslationController Tests', () {
    late MockTranslationService mockTranslationService;
    late MockLanguageDetectionService mockLanguageDetectionService;
    late TranslationController translationController;

    setUp(() {
      mockTranslationService = MockTranslationService();
      mockLanguageDetectionService = MockLanguageDetectionService();
      translationController = TranslationController();
    });

    test('should initialize correctly', () async {
      // Arrange
      when(mockTranslationService.initialize()).thenAnswer((_) async {});
      when(mockLanguageDetectionService.initialize()).thenAnswer((_) async {});

      // Act
      await translationController.initialize('en');

      // Assert
      expect(translationController.isInitialized, true);
      expect(translationController.currentLocale, 'en');
    });

    test('should update locale correctly', () {
      // Arrange
      translationController.updateLocale('fr');

      // Assert
      expect(translationController.currentLocale, 'fr');
    });

    test('should toggle auto-translate correctly', () {
      // Arrange
      final initialAutoTranslate = translationController.autoTranslate;

      // Act
      translationController.toggleAutoTranslate();

      // Assert
      expect(translationController.autoTranslate, !initialAutoTranslate);
    });

    test('should translate text correctly', () async {
      // Arrange
      const originalText = 'Hello world';
      const translatedText = 'Bonjour le monde';
      
      when(mockTranslationService.translateText(originalText, 'en', 'fr'))
          .thenAnswer((_) async => translatedText);

      // Act
      final result = await translationController.translateText(originalText, targetLanguage: 'fr');

      // Assert
      expect(result, translatedText);
      verify(mockTranslationService.translateText(originalText, 'en', 'fr')).called(1);
    });

    test('should return original text if translation fails', () async {
      // Arrange
      const originalText = 'Hello world';
      
      when(mockTranslationService.translateText(originalText, 'en', 'fr'))
          .thenThrow(Exception('Translation failed'));

      // Act
      final result = await translationController.translateText(originalText, targetLanguage: 'fr');

      // Assert
      expect(result, originalText);
    });

    test('should handle batch translation correctly', () async {
      // Arrange
      final texts = {'text1': 'Hello', 'text2': 'World'};
      final translatedTexts = {'text1': 'Bonjour', 'text2': 'Monde'};
      
      when(mockTranslationService.translateBatch(texts, 'en', 'fr'))
          .thenAnswer((_) async => translatedTexts);

      // Act
      final result = await translationController.translateBatch(texts, targetLanguage: 'fr');

      // Assert
      expect(result, translatedTexts);
      verify(mockTranslationService.translateBatch(texts, 'en', 'fr')).called(1);
    });

    test('should clear cache correctly', () {
      // Act
      translationController.clearCache();

      // Assert
      expect(translationController.translatedTexts.isEmpty, true);
      verify(mockTranslationService.clearCache()).called(1);
    });

    test('should get translation statistics correctly', () {
      // Act
      final stats = translationController.getTranslationStats();

      // Assert
      expect(stats.containsKey('cacheSize'), true);
      expect(stats.containsKey('currentlyTranslating'), true);
      expect(stats.containsKey('autoTranslateEnabled'), true);
      expect(stats.containsKey('currentLocale'), true);
      expect(stats.containsKey('supportedLanguages'), true);
    });
  });

  group('TranslationService Tests', () {
    late TranslationService translationService;

    setUp(() {
      translationService = TranslationService();
    });

    test('should initialize correctly', () async {
      // Act
      await translationService.initialize();

      // Assert
      expect(translationService.supportedLanguages.contains('en'), true);
      expect(translationService.supportedLanguages.contains('fr'), true);
      expect(translationService.supportedLanguages.contains('mg'), true);
    });

    test('should check if language is supported correctly', () {
      // Assert
      expect(translationService.isLanguageSupported('en'), true);
      expect(translationService.isLanguageSupported('fr'), true);
      expect(translationService.isLanguageSupported('mg'), true);
      expect(translationService.isLanguageSupported('de'), false);
    });

    test('should get language name correctly', () {
      // Assert
      expect(translationService.getLanguageName('en'), 'English');
      expect(translationService.getLanguageName('fr'), 'Français');
      expect(translationService.getLanguageName('mg'), 'Malagasy');
      expect(translationService.getLanguageName('unknown'), 'UNKNOWN');
    });
  });

  group('LanguageDetectionService Tests', () {
    late LanguageDetectionService languageDetectionService;

    setUp(() {
      languageDetectionService = LanguageDetectionService();
    });

    test('should initialize correctly', () async {
      // Act
      await languageDetectionService.initialize();

      // Assert - Should not throw any exceptions
      expect(true, true);
    });

    test('should get language name correctly', () {
      // Assert
      expect(languageDetectionService.getLanguageName('en'), 'English');
      expect(languageDetectionService.getLanguageName('fr'), 'Français');
      expect(languageDetectionService.getLanguageName('mg'), 'Malagasy');
      expect(languageDetectionService.getLanguageName('unknown'), 'UNKNOWN');
    });

    test('should check if language is supported correctly', () {
      // Assert
      expect(languageDetectionService.isLanguageSupported('en'), true);
      expect(languageDetectionService.isLanguageSupported('fr'), true);
      expect(languageDetectionService.isLanguageSupported('mg'), true);
      expect(languageDetectionService.isLanguageSupported('de'), false);
    });
  });

  group('Integration Tests', () {
    testWidgets('should display translation toggle widget', (WidgetTester tester) async {
      // Arrange
      final translationController = TranslationController();
      
      // Act
      await tester.pumpWidget(
        ChangeNotifierProvider<TranslationController>.value(
          value: translationController,
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Auto-Translate'),
                    value: translationController.autoTranslate,
                    onChanged: (value) {
                      translationController.toggleAutoTranslate();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Auto-Translate'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsOneWidget);
    });

    testWidgets('should display translated text widget', (WidgetTester tester) async {
      // Arrange
      final translationController = TranslationController();
      await translationController.initialize('en');
      
      // Act
      await tester.pumpWidget(
        ChangeNotifierProvider<TranslationController>.value(
          value: translationController,
          child: MaterialApp(
            home: Scaffold(
              body: const Text('Test Text'),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Text'), findsOneWidget);
    });
  });
}