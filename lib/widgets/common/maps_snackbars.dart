import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;

class MapsErrorSnackBar {
  static void show(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Could not open maps. Please install a maps application.'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Download',
          textColor: Colors.white,
          onPressed: () async {
            if (Platform.isAndroid) {
              final playStoreIntent = AndroidIntent(
                action: 'action_view',
                data: Uri.encodeFull(
                    'https://play.google.com/store/apps/details?id=com.google.android.apps.maps'),
              );
              await playStoreIntent.launch();
            } else {
              final appStoreUrl = Uri.parse(
                  'https://apps.apple.com/app/google-maps/id585027354');
              if (await canLaunchUrl(appStoreUrl)) {
                await launchUrl(appStoreUrl, mode: LaunchMode.externalApplication);
              }
            }
          },
        ),
      ),
    );
  }
}

class MapsRedirectSnackBar {
  static void show(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Redirecting to Google Maps download...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }
}