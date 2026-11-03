import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fihirana/features/admin/data/services/admin_control_service.dart';

/// The admin config reaches the model from two places: Firestore answers with a
/// `Timestamp`, the offline SharedPreferences copy comes back out of `jsonEncode`
/// as whatever JSON can hold. Reading only the Firestore shape is what made the
/// cache useless - the write threw, so nothing was ever stored, and the offline
/// fallback silently returned defaults.
void main() {
  final moment = DateTime.utc(2026, 11, 3, 9, 30);

  Map<String, dynamic> row(Object? timestamp) => {
        'updatesEnabled': false,
        'forceUpdate': true,
        'emergencyMode': true,
        'adminMessage': 'Maintenance',
        'allowedVersions': ['1.0.55', '1.0.56'],
        'timestamp': timestamp,
      };

  test('a Firestore timestamp reads back as the same instant', () {
    final config = AdminConfig.fromMap(row(Timestamp.fromDate(moment)));

    expect(config.configTimestamp, moment.toLocal());
    expect(config.emergencyMode, isTrue);
    expect(config.updatesEnabled, isFalse);
  });

  test('a cached timestamp survives the JSON round trip', () {
    final original = AdminConfig(
      updatesEnabled: false,
      emergencyMode: true,
      configTimestamp: moment,
    );

    // Exactly what the offline cache writes: the Firestore map with the
    // timestamp replaced by the JSON-encodable form.
    final cached = Map<String, dynamic>.from(original.toMap())
      ..['timestamp'] = moment.millisecondsSinceEpoch;

    final decoded = AdminConfig.fromMap(
        jsonDecode(jsonEncode(cached)) as Map<String, dynamic>);

    expect(decoded.configTimestamp, moment.toLocal(),
        reason: 'the cache has to hand back the instant it was given');
    expect(decoded.emergencyMode, isTrue,
        reason: 'an emergency stop must survive an offline start');
    expect(decoded.updatesEnabled, isFalse);
  });

  test('an absent or unreadable timestamp costs only the timestamp', () {
    for (final bad in [null, 'not a date', #symbol]) {
      final config = AdminConfig.fromMap(row(bad));
      expect(config.configTimestamp, isNull, reason: 'from $bad');
      expect(config.allowedVersions, hasLength(2));
    }
  });

  test('an ISO timestamp is read too, not only millis', () {
    final config = AdminConfig.fromMap(row(moment.toIso8601String()));
    expect(config.configTimestamp?.toUtc(), moment);
  });

  test('a default config has no timestamp to encode', () {
    expect(AdminConfig.fromMap(row(null)).configTimestamp, isNull);
  });
}
