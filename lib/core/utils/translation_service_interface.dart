abstract class ITranslationService {
  Future<void> initialize();
  Future<String> translate({
    required String text,
    String sourceLanguage = 'auto',
    String targetLanguage = 'en',
  });
  Future<String> translateText(String text, String from, String to);
  Future<Map<String, String>> translateBatch(
      Map<String, String> texts, String from, String to);
  Future<String> detectLanguage(String text);
}
