import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'local_storage_service.dart';

class DownloadManager {
  final LocalStorageService _storageService;

  DownloadManager({
    required LocalStorageService storageService,
  }) : _storageService = storageService;

  Future<void> initNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'hymn_download_channel',
          channelName: 'Maka Hira',
          channelDescription: 'Notifications for hymn downloads and updates',
          defaultColor: const Color(0xFF9D50DD),
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
      debug: true,
    );
  }

  Future<void> downloadHymns({
    Function(double)? onProgress,
    Function(String)? onError,
  }) async {

    if (onProgress != null) {
      onProgress(1.0);
    }
  }

  Future<bool> checkForUpdates() async {

    return false;
  }

  Future<void> _showNotification(String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'hymn_download_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
    );
  }
}