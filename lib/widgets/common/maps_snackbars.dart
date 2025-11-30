import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io' show Platform;
import '../../l10n/app_localizations.dart';

class MapsErrorSnackBar {
  static void show(BuildContext context, dynamic error) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.couldNotOpenMaps),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: l10n.download,
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
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.redirectingToGoogleMaps),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }
}