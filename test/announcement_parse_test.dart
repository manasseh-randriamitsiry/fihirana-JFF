import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fihirana/features/announcement/domain/entities/announcement.dart';

/// Announcement rows are written by the admin UI, by the console and, in older
/// installs, by builds with a different shape. One unreadable row must cost one
/// row, not the whole list.
void main() {
  final createdAt = Timestamp.fromDate(DateTime.utc(2026, 11, 3));

  Map<String, dynamic> validRow() => {
        'title': 'Misikam-bava',
        'message': 'The hymn book update is ready.',
        'createdAt': createdAt,
        'expiresAt': null,
        'createdBy': 'admin',
        'createdByEmail': 'admin@example.com',
      };

  test('a well-formed row parses', () {
    final announcement = Announcement.tryFromData(validRow(), id: 'a1');

    expect(announcement, isNotNull);
    expect(announcement!.id, 'a1');
    expect(announcement.title, 'Misikam-bava');
    expect(announcement.createdAt, createdAt.toDate(),
        reason: 'the entity hands back the local instant of the stored stamp');
    expect(announcement.expiresAt, isNull);
  });

  test('a row without a server timestamp is dropped, not thrown', () {
    for (final bad in [
      null,
      '2026-11-03',
      1730592000,
      DateTime.utc(2026, 11, 3).toIso8601String(),
    ]) {
      final row = validRow()..['createdAt'] = bad;
      expect(Announcement.tryFromData(row, id: 'a1'), isNull,
          reason: 'createdAt of $bad (${bad.runtimeType}) is unreadable');
    }
  });

  test('a row without readable text is dropped', () {
    for (final field in ['title', 'message']) {
      for (final bad in [null, 42, true]) {
        final row = validRow()..[field] = bad;
        expect(Announcement.tryFromData(row, id: 'a1'), isNull,
            reason: '$field of $bad is unreadable');
      }
    }
  });

  test('a malformed optional field degrades instead of losing the row', () {
    for (final bad in ['tomorrow', 7, DateTime.utc(2026, 12, 1)]) {
      final row = validRow()
        ..['expiresAt'] = bad
        ..['createdBy'] = null
        ..['createdByEmail'] = 0;
      final announcement = Announcement.tryFromData(row, id: 'a1');

      expect(announcement, isNotNull,
          reason: 'expiresAt of $bad must not delete an otherwise valid row');
      expect(announcement!.expiresAt, isNull);
      expect(announcement.createdBy, isEmpty);
      expect(announcement.createdByEmail, isEmpty);
    }
  });

  test('a missing document body is dropped', () {
    expect(Announcement.tryFromData(null, id: 'a1'), isNull);
  });

  test('a dropped row does not affect its neighbours', () {
    final rows = [validRow(), validRow()..['createdAt'] = 'not a timestamp'];
    final parsed =
        rows.map((row) => Announcement.tryFromData(row, id: 'a1')).nonNulls;

    expect(parsed, hasLength(1));
  });
}
