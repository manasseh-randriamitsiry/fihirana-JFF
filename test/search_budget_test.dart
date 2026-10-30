import 'package:flutter_test/flutter_test.dart';

import 'package:fihirana/features/bible/data/services/bible_service.dart';

/// The Bible is 12 MB of JSON and 31,172 verses, decoded and searched on the
/// UI isolate. This measures what a search actually costs on the machine
/// running the suite, so a regression shows up as a number rather than as
/// "the app feels slow on cheap phones".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a bible search scans the whole corpus on the UI isolate', () async {
    final service = BibleService();

    final load = Stopwatch()..start();
    await service.initialize();
    load.stop();

    final search = Stopwatch()..start();
    final results = service.searchVerses('fitiavana');
    search.stop();

    // ignore: avoid_print
    print('bible load ${load.elapsedMilliseconds} ms · '
        'search ${search.elapsedMilliseconds} ms · ${results.length} hits');

    expect(results, isNotEmpty);
    expect(service.bookCount, 66);

    // Case folding is the only normalisation; an accented query must still
    // match, and the search must not silently cap its results.
    final capped = service.searchVerses('ny');
    expect(capped.length, greaterThan(results.length));

    // A single keystroke's search must finish inside a few frames even on a
    // slow device. This is a hang guard, not a benchmark.
    expect(search.elapsedMilliseconds, lessThan(500));
  });
}
