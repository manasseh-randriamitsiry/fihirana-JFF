import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The hymns and the Bible ship as JSON that nothing type-checks at build
/// time. A malformed record does not fail the build; it reaches the reader as
/// a blank page, a skipped verse or a hymn that silently disappears.
void main() {
  Map<String, dynamic> readJson(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  test('every hymn in the served corpus is complete and uniquely numbered', () {
    final combined = readJson('assets/hymns_combined.json');
    final hymns = combined['hymns'] as List;

    expect(hymns, hasLength(828));
    expect(combined['total'], hymns.length,
        reason: 'the corpus header disagrees with the list it ships');

    final seen = <String>{};
    for (final raw in hymns) {
      final hymn = raw as Map<String, dynamic>;
      final number = (hymn['number'] ?? '').toString().trim();
      expect(number, isNotEmpty, reason: 'hymn without a number: $hymn');
      expect(seen.add(number), isTrue, reason: 'duplicate hymn number $number');

      expect((hymn['title'] as String? ?? '').trim(), isNotEmpty,
          reason: 'hymn $number has no title');

      final verses = hymn['verses'];
      expect(verses, isA<Map<String, dynamic>>(),
          reason: 'hymn $number must key its verses by number');
      final keys = (verses as Map<String, dynamic>).keys.toList();
      expect(
          keys, unorderedEquals([for (var i = 1; i <= keys.length; i++) '$i']),
          reason: 'hymn $number skips a verse number');
      for (final entry in verses.entries) {
        expect((entry.value as String).trim(), isNotEmpty,
            reason: 'hymn $number verse ${entry.key} is blank');
      }

      final chorus = hymn['chorus'];
      if (chorus != null) {
        expect((chorus as String).trim(), isNotEmpty,
            reason: 'hymn $number has a blank chorus');
      }
    }
  });

  test('every hymn file parses and the manifest only adds known breakage', () {
    final files = Directory('assets/json')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList();
    expect(files, hasLength(828));

    for (final file in files) {
      final hymn = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect((hymn['title'] as String? ?? '').trim(), isNotEmpty,
          reason: '${file.path} has no title');
      expect(hymn['verses'], isNotEmpty, reason: '${file.path} has no verses');
    }

    final manifest = readJson('assets/hymn_manifest.json');
    expect(manifest, hasLength(828));

    final broken = manifest.entries
        .where((entry) => !File(entry.value as String).existsSync())
        .map((entry) => entry.key)
        .toSet();

    // Known and unfixed: 257 was renamed on disk without updating the manifest.
    expect(
      broken,
      {'257-AKAIKINAO-NY-VARAVARANA'},
      reason: 'new dangling manifest entries: $broken',
    );
  });

  test('every bible chapter is intact', () {
    final books = readJson('assets/baiboly/bible.json')['books'] as List;
    expect(books, hasLength(66));

    var verseCount = 0;
    final blank = <String>[];
    for (final rawBook in books) {
      final book = rawBook as Map<String, dynamic>;
      final chapters = book['chapters'] as List;
      expect(chapters, isNotEmpty, reason: '${book['name']} has no chapters');

      for (var c = 0; c < chapters.length; c++) {
        final chapter = chapters[c] as Map<String, dynamic>;
        expect(chapter['chapter'], c + 1,
            reason: '${book['name']} chapter order');
        final rows = chapter['verses'] as List;
        expect(rows, isNotEmpty,
            reason: '${book['name']} ${c + 1} has no verses');

        for (var v = 0; v < rows.length; v++) {
          final verse = rows[v] as Map<String, dynamic>;
          expect(verse['verse'], v + 1,
              reason: '${book['name']} ${c + 1} verse order');
          if ((verse['text'] as String? ?? '').trim().isEmpty) {
            blank
                .add('${book['name']} ${chapter['chapter']}:${verse['verse']}');
          }
          verseCount++;
        }
      }
    }

    expect(verseCount, 31172);

    // 58 Psalms arrived with their superscription where verse 1 belongs and no
    // text behind it, plus 9 scattered gaps. The number is a ratchet: the
    // corpus may gain text, never more blanks.
    expect(blank, hasLength(67),
        reason: 'blank verses changed: ${blank.join(', ')}');
  });
}
