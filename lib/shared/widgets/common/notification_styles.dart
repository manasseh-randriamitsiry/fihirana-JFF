import 'dart:ui' show Brightness, Color, PlatformDispatcher;

import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationLayouts {
  /// Awesome Notifications defaults to black when no color is provided.
  /// Select the seed from the device's light/dark mode instead of the app theme.
  static Color get _systemNotificationColor =>
      PlatformDispatcher.instance.platformBrightness == Brightness.dark
          ? const Color(0xFF000000)
          : const Color(0xFFFFFFFF);

  static NotificationContent createBasicNotification({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    String? payload,
    NotificationLayout? layout,
  }) {
    return NotificationContent(
      id: id,
      channelKey: channelKey,
      title: title,
      body: body,
      color: _systemNotificationColor,
      notificationLayout: layout ?? NotificationLayout.Default,
      payload: payload != null ? {'data': payload} : null,
    );
  }

  static NotificationContent createSuccessNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) {
    return NotificationContent(
      id: id,
      channelKey: 'basic_channel',
      title: title,
      body: body,
      color: _systemNotificationColor,
      notificationLayout: NotificationLayout.Inbox,
      badge: AwesomeNotifications.maxID,
      payload: payload != null ? {'data': payload} : null,
    );
  }

  static NotificationContent createErrorNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) {
    return NotificationContent(
      id: id,
      channelKey: 'basic_channel',
      title: title,
      body: body,
      notificationLayout: NotificationLayout.Default,
      payload: payload != null ? {'data': payload} : null,
    );
  }

  static NotificationContent createBigTextNotification({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    String? payload,
    Map<String, String>? additionalPayload,
  }) {
    final Map<String, String> fullPayload = {};
    if (payload != null) fullPayload['data'] = payload;
    if (additionalPayload != null) fullPayload.addAll(additionalPayload);

    return NotificationContent(
      id: id,
      channelKey: channelKey,
      title: title,
      body: body,
      notificationLayout: NotificationLayout.BigText,
      color: _systemNotificationColor,
      payload: fullPayload.isNotEmpty ? fullPayload : null,
    );
  }

  static NotificationContent createProgressBarNotification({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    required double progress,
    bool locked = false,
    bool autoDismissible = true,
    List<NotificationActionButton>? actionButtons,
  }) {
    return NotificationContent(
      id: id,
      channelKey: channelKey,
      title: title,
      body: body,
      notificationLayout: NotificationLayout.ProgressBar,
      progress: progress,
      locked: locked,
      autoDismissible: autoDismissible,
      color: _systemNotificationColor,
    );
  }

  static NotificationContent createMediaPlayerNotification({
    required int id,
    required String title,
    required String body,
    String? largeIcon,
    double? progress,
    bool locked = false,
    bool autoDismissible = true,
    String? summary,
  }) {
    return NotificationContent(
      id: id,
      channelKey: 'audio_player_channel',
      title: title,
      body: body,
      category: NotificationCategory.Transport,
      notificationLayout: NotificationLayout.MediaPlayer,
      color: _systemNotificationColor,
      autoDismissible: autoDismissible,
      displayOnForeground: true,
      displayOnBackground: true,
      wakeUpScreen: false,
      fullScreenIntent: false,
      locked: locked,
      summary: summary ?? 'Fihirana - Music Player',
      largeIcon: largeIcon ?? 'resource://mipmap/ic_launcher',
      roundedLargeIcon: true,
      progress: progress,
    );
  }
}

class NotificationButtons {
  static List<NotificationActionButton> createDownloadButtons({
    required String cancelKey,
    String cancelLabel = 'Ajanona',
    String? cancelIcon,
    bool showCancel = true,
  }) {
    final buttons = <NotificationActionButton>[];

    if (showCancel) {
      buttons.add(NotificationActionButton(
        key: cancelKey,
        label: cancelLabel,
        actionType: ActionType.Default,
        icon: cancelIcon ?? 'resource://mipmap/ic_launcher',
      ));
    }

    return buttons;
  }

  static List<NotificationActionButton> createUpdateButtons({
    required String updateKey,
    required String dismissKey,
    String updateLabel = 'Haka',
    String dismissLabel = 'Mbola tsy izao aloha',
    String? updateIcon,
    String? dismissIcon,
  }) {
    return [
      NotificationActionButton(
        key: updateKey,
        label: updateLabel,
        icon: updateIcon ?? 'resource://mipmap/ic_launcher',
      ),
      NotificationActionButton(
        key: dismissKey,
        label: dismissLabel,
        actionType: ActionType.Default,
        icon: dismissIcon ?? 'resource://mipmap/ic_launcher',
      ),
    ];
  }

  static List<NotificationActionButton> createAudioPlayerButtons({
    required bool isPlaying,
    required bool canGoNext,
    required bool canGoPrevious,
  }) {
    return [
      NotificationActionButton(
        key: 'prev',
        label: 'Précédent',
        icon: 'resource://drawable/ic_skip_previous',
        enabled: canGoPrevious,
        autoDismissible: false,
        showInCompactView: true,
        actionType: ActionType.KeepOnTop,
      ),
      NotificationActionButton(
        key: isPlaying ? 'pause' : 'play',
        label: isPlaying ? 'Pause' : 'Lire',
        icon: isPlaying
            ? 'resource://drawable/ic_pause'
            : 'resource://drawable/ic_play',
        enabled: true,
        autoDismissible: false,
        showInCompactView: true,
        actionType: ActionType.KeepOnTop,
      ),
      NotificationActionButton(
        key: 'next',
        label: 'Suivant',
        icon: 'resource://drawable/ic_skip_next',
        enabled: canGoNext,
        autoDismissible: false,
        showInCompactView: true,
        actionType: ActionType.KeepOnTop,
      ),
      NotificationActionButton(
        key: 'stop',
        label: 'Stop',
        icon: 'resource://drawable/ic_stop',
        enabled: true,
        autoDismissible: false,
        showInCompactView: false,
        actionType: ActionType.KeepOnTop,
      ),
    ];
  }

  static List<NotificationActionButton> createAnnouncementButtons({
    required String openKey,
    String openLabel = 'Hijery',
  }) {
    return [
      NotificationActionButton(
        key: openKey,
        label: openLabel,
        actionType: ActionType.Default,
      ),
    ];
  }
}
