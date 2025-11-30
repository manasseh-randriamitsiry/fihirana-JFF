import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:flutter/foundation.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  OnDeviceTranslator? _translator;
  String _currentSourceLanguage = 'en';
  String _currentTargetLanguage = 'en';

  Future<String> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      if (text.isEmpty) return '';

      // Create new translator if language pair changed or translator doesn't exist
      if (_translator == null || 
          _currentSourceLanguage != sourceLanguage || 
          _currentTargetLanguage != targetLanguage) {
        
        // Close existing translator
        if (_translator != null) {
          await _translator!.close();
        }

        final sourceLang = _getTranslateLanguage(sourceLanguage);
        final targetLang = _getTranslateLanguage(targetLanguage);

        _translator = OnDeviceTranslator(
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
        );

        _currentSourceLanguage = sourceLanguage;
        _currentTargetLanguage = targetLanguage;
      }

      final translation = await _translator!.translateText(text);
      return translation;
    } catch (e) {
      if (kDebugMode) {
        print('Error translating text: $e');
      }
      return text; // Return original text on error
    }
  }

  Future<bool> isModelDownloaded(String languageCode) async {
    try {
      final modelManager = OnDeviceTranslatorModelManager();
      final lang = _getTranslateLanguage(languageCode);
      return await modelManager.isModelDownloaded(lang.bcpCode);
    } catch (e) {
      return false;
    }
  }

  Future<bool> downloadModel(String languageCode) async {
    try {
      final modelManager = OnDeviceTranslatorModelManager();
      final lang = _getTranslateLanguage(languageCode);
      return await modelManager.downloadModel(lang.bcpCode);
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading model: $e');
      }
      return false;
    }
  }

  Future<void> deleteModel(String languageCode) async {
    try {
      final modelManager = OnDeviceTranslatorModelManager();
      final lang = _getTranslateLanguage(languageCode);
      await modelManager.deleteModel(lang.bcpCode);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting model: $e');
      }
    }
  }

  // Helper method to get TranslateLanguage from language code
  TranslateLanguage _getTranslateLanguage(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'en':
        return TranslateLanguage.english;
      case 'af':
        return TranslateLanguage.afrikaans;
      case 'ar':
        return TranslateLanguage.arabic;
      case 'be':
        return TranslateLanguage.belarusian;
      case 'bg':
        return TranslateLanguage.bulgarian;
      case 'bn':
        return TranslateLanguage.bengali;
      case 'ca':
        return TranslateLanguage.catalan;
      case 'cs':
        return TranslateLanguage.czech;
      case 'cy':
        return TranslateLanguage.welsh;
      case 'da':
        return TranslateLanguage.danish;
      case 'de':
        return TranslateLanguage.german;
      case 'el':
        return TranslateLanguage.greek;
      case 'es':
        return TranslateLanguage.spanish;
      case 'et':
        return TranslateLanguage.estonian;
      case 'fa':
        return TranslateLanguage.persian;
      case 'fi':
        return TranslateLanguage.finnish;
      case 'fr':
        return TranslateLanguage.french;
      case 'ga':
        return TranslateLanguage.irish;
      case 'gl':
        return TranslateLanguage.galician;
      case 'gu':
        return TranslateLanguage.gujarati;
      case 'he':
        return TranslateLanguage.hebrew;
      case 'hi':
        return TranslateLanguage.hindi;
      case 'hr':
        return TranslateLanguage.croatian;
      case 'ht':
        return TranslateLanguage.haitian;
      case 'hu':
        return TranslateLanguage.hungarian;
      case 'id':
        return TranslateLanguage.indonesian;
      case 'is':
        return TranslateLanguage.icelandic;
      case 'it':
        return TranslateLanguage.italian;
      case 'ja':
        return TranslateLanguage.japanese;
      case 'ka':
        return TranslateLanguage.georgian;
      case 'kn':
        return TranslateLanguage.kannada;
      case 'ko':
        return TranslateLanguage.korean;
      case 'lt':
        return TranslateLanguage.lithuanian;
      case 'lv':
        return TranslateLanguage.latvian;
      case 'mk':
        return TranslateLanguage.macedonian;
      case 'mr':
        return TranslateLanguage.marathi;
      case 'ms':
        return TranslateLanguage.malay;
      case 'mt':
        return TranslateLanguage.maltese;
      case 'nl':
        return TranslateLanguage.dutch;
      case 'no':
        return TranslateLanguage.norwegian;
      case 'pl':
        return TranslateLanguage.polish;
      case 'pt':
        return TranslateLanguage.portuguese;
      case 'ro':
        return TranslateLanguage.romanian;
      case 'ru':
        return TranslateLanguage.russian;
      case 'sk':
        return TranslateLanguage.slovak;
      case 'sl':
        return TranslateLanguage.slovenian;
      case 'sq':
        return TranslateLanguage.albanian;
      case 'sv':
        return TranslateLanguage.swedish;
      case 'sw':
        return TranslateLanguage.swahili;
      case 'ta':
        return TranslateLanguage.tamil;
      case 'te':
        return TranslateLanguage.telugu;
      case 'th':
        return TranslateLanguage.thai;
      case 'tl':
        return TranslateLanguage.tagalog;
      case 'tr':
        return TranslateLanguage.turkish;
      case 'uk':
        return TranslateLanguage.ukrainian;
      case 'ur':
        return TranslateLanguage.urdu;
      case 'vi':
        return TranslateLanguage.vietnamese;
      case 'zh':
        return TranslateLanguage.chinese;
      default:
        return TranslateLanguage.english;
    }
  }

  void dispose() {
    if (_translator != null) {
      _translator!.close();
    }
  }
}
