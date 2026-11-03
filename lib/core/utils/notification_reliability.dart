import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// What stands between the daily verse and the minute the user chose.
enum DeliveryBlocker { none, notifications, exactAlarms, batteryOptimization }

/// Whether the system is currently free to delay or drop a scheduled verse.
///
/// Three settings decide it and the user owns all three: the notification
/// permission, the exact-alarm permission (revoked by default since Android 12)
/// and the Doze whitelist. This class reports them and opens the screen that
/// changes the one in the way. It never requests an exemption programmatically:
/// that route is what Play's background-execution policy rejects.
class NotificationReliability {
  NotificationReliability({MethodChannel? powerChannel})
      : _power = powerChannel ?? const MethodChannel(_channelName);

  static const String _channelName = 'com.manasseh.fihirana_jff/power';

  final MethodChannel _power;

  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// A device that does not answer is treated as free to deliver: this class
  /// exists to warn about a real block, not to invent one.
  Future<bool> _ask(String method) async {
    if (!_isAndroid) return true;
    try {
      return await _power.invokeMethod<bool>(method) ?? true;
    } on MissingPluginException {
      return true;
    } on PlatformException {
      return true;
    }
  }

  Future<bool> get notificationsEnabled => _ask('areNotificationsEnabled');

  Future<bool> get exactAlarmsAllowed => _ask('canScheduleExactAlarms');

  Future<bool> get ignoresBatteryOptimizations =>
      _ask('isIgnoringBatteryOptimizations');

  /// The first thing in the way, in the order the system enforces it: without
  /// notifications nothing is shown at all, without exact alarms the verse
  /// lands in whatever window Doze picks, and without a Doze exemption an
  /// idle phone can hold both back.
  Future<DeliveryBlocker> get blocker async {
    if (!await notificationsEnabled) return DeliveryBlocker.notifications;
    if (!await exactAlarmsAllowed) return DeliveryBlocker.exactAlarms;
    if (!await ignoresBatteryOptimizations) {
      return DeliveryBlocker.batteryOptimization;
    }
    return DeliveryBlocker.none;
  }

  Future<bool> get isAtRisk async =>
      await blocker != DeliveryBlocker.none;

  /// Opens the prompt or screen for [blocker]. The return value is whether the
  /// check verifiably passed afterwards, which only the notification prompt can
  /// answer inline - a settings page comes back before the user has decided, so
  /// those are re-read when the app next resumes.
  Future<bool> resolve(DeliveryBlocker blocker) async {
    switch (blocker) {
      case DeliveryBlocker.none:
        return false;
      case DeliveryBlocker.notifications:
        await AwesomeNotifications().requestPermissionToSendNotifications();
        return await notificationsEnabled;
      case DeliveryBlocker.exactAlarms:
        await AwesomeNotifications().showAlarmPage();
        return false;
      case DeliveryBlocker.batteryOptimization:
        await _power.invokeMethod<void>('openBatteryOptimizationSettings');
        return false;
    }
  }
}
