// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:fihirana/features/bible/data/services/bible_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Bible search test', () async {
    final bibleService = BibleService();
    await bibleService.initialize();

    print('Testing search for: "Josoa"');
    final results = bibleService.searchVerses('Josoa');
    print('Found ${results.length} results');
    for (final res in results.take(10)) {
      print('${res.bookName} ${res.chapter}:${res.verse} -> ${res.text}');
    }

    expect(results, isNotEmpty);
  });
}
