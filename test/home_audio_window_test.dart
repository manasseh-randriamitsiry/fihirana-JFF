import 'package:flutter_test/flutter_test.dart';

import 'package:fihirana/features/home/presentation/pages/accueil_screen.dart';

void main() {
  group('audioWindowIndices', () {
    test('checks the initial viewport and one screenful ahead', () {
      expect(
        audioWindowIndices(offset: 0, viewport: 680, itemCount: 100),
        List<int>.generate(20, (index) => index),
      );
    });

    test('moves the whole check window after scrolling', () {
      expect(
        audioWindowIndices(offset: 680, viewport: 680, itemCount: 100),
        List<int>.generate(20, (index) => index + 10),
      );
    });

    test('clamps short lists and the end of the list', () {
      expect(
        audioWindowIndices(offset: 0, viewport: 680, itemCount: 5),
        List<int>.generate(5, (index) => index),
      );
      expect(
        audioWindowIndices(offset: 1360, viewport: 680, itemCount: 30),
        List<int>.generate(10, (index) => index + 20),
      );
    });

    test('returns no rows for an empty list', () {
      expect(
        audioWindowIndices(offset: 0, viewport: 680, itemCount: 0),
        isEmpty,
      );
    });
  });
}
