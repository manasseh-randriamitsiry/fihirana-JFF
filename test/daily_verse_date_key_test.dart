import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fihirana/features/daily_verse/data/services/daily_verse_service.dart';

/// A single-digit day used to build '2026-11-3', which DateTime.parse rejects,
/// so the cached verse threw every day from the 1st to the 9th of a month.
void main() {
  test('today reads back as the same key it was stored under', () async {
    final today = DateTime.now();
    final key = today.toIso8601String().substring(0, 10);

    SharedPreferences.setMockInitialValues({
      'last_daily_verse_date': key,
      'last_daily_verse_book': 'Matio',
      'last_daily_verse_chapter': 5,
      'last_daily_verse_verse': 3,
      'last_daily_verse_text': 'Bay mianaka aho.',
      'last_daily_verse_reference': 'Matio 5:3',
    });

    final verse = await DailyVerseService().getVerseOfTheDay();

    expect(verse.book, 'Matio');
    expect(verse.text, 'Bay mianaka aho.');
    expect(verse.date.year, today.year);
  });
}
