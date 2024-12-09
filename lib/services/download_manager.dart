import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../models/hymn.dart';
import 'local_storage_service.dart';

class DownloadManager {
  final LocalStorageService _storageService;
  final FirebaseFirestore _firestore;

  DownloadManager({
    required LocalStorageService storageService,
    FirebaseFirestore? firestore,
  })  : _storageService = storageService,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> initNotifications() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'hymn_download_channel',
          channelName: 'Hymn Downloads',
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
    try {
      // Get total number of hymns
      final QuerySnapshot querySnapshot = await _firestore.collection('hymns').get();
      final int total = querySnapshot.docs.length;
      int downloaded = 0;

      if (total == 0) {
        if (onError != null) {
          onError('No hymns found in the database');
        }
        return;
      }

      final List<Hymn> hymns = [];
      
      // Process each document
      for (var doc in querySnapshot.docs) {
        try {
          final hymn = Hymn.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
          hymns.add(hymn);
          
          downloaded++;
          if (onProgress != null) {
            onProgress(downloaded / total);
          }
        } catch (e) {
          print('Error processing hymn document: $e');
          // Continue with next document instead of failing completely
          continue;
        }
      }

      // Save hymns locally only if we have successfully processed some
      if (hymns.isNotEmpty) {
        await _storageService.saveHymns(hymns);
        
        // Update last update timestamp
        await _storageService.setLastUpdate(DateTime.now());

        await _showNotification(
          'Download Complete',
          '${hymns.length} hymns have been downloaded successfully',
        );
      } else {
        throw Exception('No hymns were successfully processed');
      }

    } catch (e) {
      print('Download error: $e');
      if (onError != null) {
        onError(e.toString());
      }
      await _showNotification(
        'Download Failed',
        'Failed to download hymns: ${e.toString()}',
      );
      rethrow; // Rethrow to handle in UI
    }
  }

  Future<bool> checkForUpdates() async {
    try {
      final lastUpdate = _storageService.getLastUpdate();
      if (lastUpdate == null) return true;

      final latestHymn = await _firestore
          .collection('hymns')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (latestHymn.docs.isEmpty) return false;

      final latestTimestamp =
          (latestHymn.docs.first.data()['createdAt'] as Timestamp).toDate();
      return latestTimestamp.isAfter(lastUpdate);
    } catch (e) {
      print('Error checking for updates: $e');
      return false;
    }
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
