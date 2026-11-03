import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications/awesome_notifications_empty.dart';
import 'package:awesome_notifications/awesome_notifications_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fihirana/core/utils/notification_reliability.dart';
import 'package:fihirana/shared/widgets/common/daily_verse_notification.dart';

/// The platform answers this class can get from a fake channel. A `null`
/// return for an unimplemented method reaches the app as a
/// MissingPluginException, which the service reads as "allowed".
class _FakePower {
  _FakePower({
    this.notificationsEnabled = true,
    this.canScheduleExactAlarms = true,
    this.ignoresBatteryOptimizations = true,
    this.grantsAfterFirstRead = false,
  });

  bool? notificationsEnabled;
  bool? canScheduleExactAlarms;
  bool? ignoresBatteryOptimizations;

  /// Simulates the user accepting the system prompt: the permission reads as
  /// denied until it has been asked once, then as granted.
  final bool grantsAfterFirstRead;

  final List<String> calls = [];

  void install(MethodChannel channel) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'areNotificationsEnabled':
          final askedTwice = calls
                  .where((method) => method == 'areNotificationsEnabled')
                  .length >
              1;
          if (grantsAfterFirstRead && askedTwice) return true;
          return notificationsEnabled;
        case 'canScheduleExactAlarms':
          return canScheduleExactAlarms;
        case 'isIgnoringBatteryOptimizations':
          return ignoresBatteryOptimizations;
        default:
          return null;
      }
    });
  }
}

/// Stands in for the notification plugin so the resolve path can be observed
/// without a native side: [grantsPermission] is what the user answers the
/// system prompt with.
class _FakeNotifications extends AwesomeNotificationsEmpty {
  bool grantsPermission = false;
  int alarmPageOpens = 0;

  @override
  Future<bool> requestPermissionToSendNotifications(
      {String? channelKey,
      List<NotificationPermission> permissions = const []}) async {
    return grantsPermission;
  }

  @override
  Future<void> showAlarmPage() async {
    alarmPageOpens++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const power = MethodChannel('com.manasseh.fihirana_jff/power');
  late _FakeNotifications plugin;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    plugin = _FakeNotifications();
    AwesomeNotificationsPlatform.instance = plugin;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    AwesomeNotificationsPlatform.resetInstance();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(power, null);
  });

  group('the daily verse alarm', () {
    test('repeats, wakes an idle device and asks for precision', () {
      final schedule = DailyVerseNotificationBuilder.dailySchedule(7, 45);

      expect(schedule.hour, 7);
      expect(schedule.minute, 45);
      expect(schedule.repeats, isTrue);
      expect(schedule.allowWhileIdle, isTrue);
      expect(schedule.preciseAlarm, isTrue);
    });

    test('names its time zone so a trip does not move the verse', () {
      final schedule = DailyVerseNotificationBuilder.dailySchedule(20, 15);

      expect(schedule.timeZone, isNotNull);
      expect(schedule.timeZone, isNotEmpty);
    });
  });

  group('the blocker', () {
    test('is nothing when the system lets the alarm through', () async {
      _FakePower().install(power);
      final reliability = NotificationReliability(powerChannel: power);

      expect(await reliability.blocker, DeliveryBlocker.none);
      expect(await reliability.isAtRisk, isFalse);
    });

    test('is the notification permission before anything else', () async {
      final fake = _FakePower(
              notificationsEnabled: false,
              canScheduleExactAlarms: false,
              ignoresBatteryOptimizations: false)
        ..install(power);
      final reliability = NotificationReliability(powerChannel: power);

      expect(await reliability.blocker, DeliveryBlocker.notifications);
      // The checks behind it are not even asked: they cannot matter while no
      // notification would be shown.
      expect(fake.calls, ['areNotificationsEnabled']);
    });

    test('is the exact-alarm permission once notifications are on', () async {
      _FakePower(canScheduleExactAlarms: false).install(power);
      final reliability = NotificationReliability(powerChannel: power);

      expect(await reliability.blocker, DeliveryBlocker.exactAlarms);
    });

    test('is Doze when the alarms themselves are allowed', () async {
      _FakePower(ignoresBatteryOptimizations: false).install(power);
      final reliability = NotificationReliability(powerChannel: power);

      expect(await reliability.blocker, DeliveryBlocker.batteryOptimization);
    });

    test('a device that answers nothing is treated as free to deliver',
        () async {
      // No mock handler: every call comes back as MissingPluginException.
      final reliability = NotificationReliability(powerChannel: power);

      expect(await reliability.isAtRisk, isFalse);
    });

    test('is never asked of the platform outside Android', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final fake = _FakePower(notificationsEnabled: false)..install(power);
      final reliability = NotificationReliability(powerChannel: power);

      expect(await reliability.isAtRisk, isFalse);
      expect(fake.calls, isEmpty);
    });
  });

  group('resolving a blocker', () {
    test('reports the verse as safe again when the prompt is accepted',
        () async {
      final fake = _FakePower(
          notificationsEnabled: false, grantsAfterFirstRead: true)
        ..install(power);
      plugin.grantsPermission = true;
      final reliability = NotificationReliability(powerChannel: power);

      expect(await reliability.blocker, DeliveryBlocker.notifications);
      expect(await reliability.resolve(DeliveryBlocker.notifications), isTrue);
      expect(fake.calls.last, 'areNotificationsEnabled');
    });

    test('reports nothing verified when the prompt is refused', () async {
      _FakePower(notificationsEnabled: false).install(power);
      plugin.grantsPermission = false;
      final reliability = NotificationReliability(powerChannel: power);

      expect(
          await reliability.resolve(DeliveryBlocker.notifications), isFalse);
    });

    test('opens the alarm page and cannot claim it was fixed', () async {
      _FakePower(canScheduleExactAlarms: false).install(power);
      final reliability = NotificationReliability(powerChannel: power);

      expect(await reliability.resolve(DeliveryBlocker.exactAlarms), isFalse);
      expect(plugin.alarmPageOpens, 1);
    });

    test('opens the battery screen and cannot claim it was fixed', () async {
      final fake = _FakePower(ignoresBatteryOptimizations: false)
        ..install(power);
      final reliability = NotificationReliability(powerChannel: power);

      expect(
          await reliability.resolve(DeliveryBlocker.batteryOptimization),
          isFalse);
      expect(fake.calls, contains('openBatteryOptimizationSettings'));
    });

    test('with nothing in the way there is nothing to open', () async {
      _FakePower().install(power);
      final reliability = NotificationReliability(powerChannel: power);

      expect(await reliability.resolve(DeliveryBlocker.none), isFalse);
      expect(plugin.alarmPageOpens, 0);
    });
  });
}
