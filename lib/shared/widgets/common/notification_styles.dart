import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationStyles {
  static const Color primaryColor = Color(0xFF9D50DD);
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color audioPlayerColor = Colors.blue;
  static const Color dailyVerseColor = Color(0xFF4CAF50);
}

class NotificationLayouts {
  static NotificationContent createBasicNotification({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    Color? color,
    String? payload,
    NotificationLayout? layout,
  }) {
    return NotificationContent(
      id: id,
      channelKey: channelKey,
      title: title,
      body: body,
      color: color ?? NotificationStyles.primaryColor,
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
      color: NotificationStyles.successColor,
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
    Color? color,
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
      color: color ?? NotificationStyles.primaryColor,
      payload: fullPayload.isNotEmpty ? fullPayload : null,
    );
  }

  static NotificationContent createProgressBarNotification({
    required int id,
    required String channelKey,
    required String title,
    required String body,
    required double progress,
    Color? color,
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
      color: color ?? NotificationStyles.primaryColor,
    );
  }

  static NotificationContent createMediaPlayerNotification({
    required int id,
    required String title,
    required String body,
    String? largeIcon,
    Color? color,
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
      color: color ?? NotificationStyles.audioPlayerColor,
      autoDismissible: autoDismissible,
      displayOnForeground: true,
      displayOnBackground: true,
      wakeUpScreen: false,
      fullScreenIntent: false,
      locked: locked,
      backgroundColor: Colors.black87,
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
        label: 'Previous',
        icon: 'resource://drawable/ic_skip_previous',
        enabled: canGoPrevious,
        autoDismissible: false,
        showInCompactView: true,
      ),
      NotificationActionButton(
        key: isPlaying ? 'pause' : 'play',
        label: isPlaying ? 'Pause' : 'Play',
        icon: isPlaying
            ? 'resource://drawable/ic_pause'
            : 'resource://drawable/ic_play',
        enabled: true,
        autoDismissible: false,
        showInCompactView: true,
      ),
      NotificationActionButton(
        key: 'next',
        label: 'Next',
        icon: 'resource://drawable/ic_skip_next',
        enabled: canGoNext,
        autoDismissible: false,
        showInCompactView: true,
      ),
      NotificationActionButton(
        key: 'rewind',
        label: '-10s',
        icon: 'resource://drawable/ic_rewind',
        enabled: true,
        autoDismissible: false,
        showInCompactView: false,
      ),
      NotificationActionButton(
        key: 'forward',
        label: '+10s',
        icon: 'resource://drawable/ic_forward',
        enabled: true,
        autoDismissible: false,
        showInCompactView: false,
      ),
      NotificationActionButton(
        key: 'stop',
        label: 'Stop',
        icon: 'resource://drawable/ic_stop',
        enabled: true,
        autoDismissible: false,
        showInCompactView: false,
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