import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fihirana/features/bible/domain/entities/bible.dart';
import 'package:fihirana/features/bible/presentation/widgets/bible_verse_selection_sheet.dart';
import 'package:fihirana/l10n/app_localizations.dart';

/// The reader stores only verses that have text, so a chapter's real verse
/// numbers can skip positions. The range picker has to work from those numbers,
/// not from `index + 1`.
void main() {
  BibleChapter parseChapter(Map<String, dynamic> chapterJson, int number) =>
      BibleChapter.fromJson(chapterJson, number);

  List<int> storedVerseNumbers(Map<String, dynamic> chapterJson) {
    final numbers =
        parseChapter(chapterJson, 1).verses.keys.toList()..sort();
    return numbers;
  }

  Future<void> pumpSheet(
    WidgetTester tester,
    List<int> verseNumbers, {
    required void Function(int start, int end) onRead,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 500,
            child: BibleVerseSelectionSheet(
              bookName: 'Salamo',
              chapter: 3,
              verseNumbers: verseNumbers,
              onReadVerses: onRead,
            ),
          ),
        ),
      ),
    );
  }

  test('a blank verse removes its number from the stored chapter', () {
    final chapter = parseChapter({
      'chapter': 3,
      'verses': [
        {'verse': 1, 'text': 'first'},
        {'verse': 2, 'text': ''},
        {'verse': 3, 'text': 'third'},
      ],
    }, 3);

    expect(chapter.verses.keys, unorderedEquals([1, 3]),
        reason: 'verse 2 has no text and must not be stored');
    expect(chapter.verses.length, isNot(3),
        reason: 'a positional count would claim verses 1, 2 and 3');
  });

  testWidgets('the picker labels cells with real verse numbers',
      (WidgetTester tester) async {
    const numbers = [1, 2, 4, 5];
    await pumpSheet(tester, const [1, 2, 4, 5], onRead: (_, __) {});

    for (final verse in numbers) {
      expect(find.text('$verse'), findsOneWidget,
          reason: 'verse $verse is stored, so it must be selectable');
    }
    expect(find.text('3'), findsNothing,
        reason: 'verse 3 does not exist in this chapter');
  });

  testWidgets('reading the whole chapter uses the first and last real verses',
      (WidgetTester tester) async {
    const numbers = [1, 2, 4, 5, 9];
    final read = <int>[];
    await pumpSheet(tester, numbers, onRead: (start, end) => read.addAll([start, end]));

    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    expect(read, [1, 9], reason: 'a positional picker would have asked for 1-5');
  });

  testWidgets('a tapped range survives confirmation unchanged',
      (WidgetTester tester) async {
    const numbers = [1, 2, 4, 5, 9];
    final read = <int>[];
    await pumpSheet(tester, numbers, onRead: (start, end) => read.addAll([start, end]));

    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.tap(find.text('9'));
    await tester.pump();
    expect(find.textContaining('Salamo 3:4-9'), findsOneWidget,
        reason: 'the summary must name the verses the user picked');

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(read, [4, 9]);
  });

  testWidgets('an empty chapter offers nothing instead of verse one',
      (WidgetTester tester) async {
    var called = false;
    await pumpSheet(tester, const [], onRead: (_, __) => called = true);

    expect(find.text('1'), findsNothing);
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();
    expect(called, isFalse, reason: 'there is no range to read');
  });

  test('the shipped corpus contains chapters whose numbering is not positional',
      () {
    final books =
        (jsonDecode(File('assets/baiboly/bible.json').readAsStringSync())
                ['books'] as List)
            .cast<Map<String, dynamic>>();

    final gapped = <String>[];
    for (final book in books) {
      for (final rawChapter in book['chapters'] as List) {
        final chapter = rawChapter as Map<String, dynamic>;
        final numbers = storedVerseNumbers(chapter);
        // A positional list starts at verse 1 and fills its own span; anything
        // else means position and verse number have diverged.
        final contiguous = numbers.first == 1 &&
            numbers.length == numbers.last - numbers.first + 1;
        if (!contiguous) {
          gapped.add('${book['name']} ${chapter['chapter']}');
        }
      }
    }

    // Today only Psalms 13 has a verse whose text is empty rather than
    // whitespace, so it is the one chapter the reader numbers non-positionally.
    // Moves with the blank-verse ratchet in corpus_integrity_test.dart: fill the
    // blanks in, and this list grows or shrinks and must be updated with it.
    expect(gapped, ['Psalms 13'],
        reason: 'non-positional chapters changed: ${gapped.join(', ')}');
  });
}
