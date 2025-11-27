import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';

class MapsLauncherService {
  static Future<void> launchMaps(double lat, double lng, {BuildContext? context}) async {
    try {
      if (Platform.isAndroid) {
        await _launchAndroidMaps(lat, lng, context);
      } else {
        await _launchiOSMaps(lat, lng);
      }
    } catch (e) {
      if (context?.mounted == true) {
        _showErrorSnackBar(context!, e);
      }
    }
  }

  static Future<void> _launchAndroidMaps(double lat, double lng, BuildContext? context) async {
    final AndroidIntent intent = AndroidIntent(
      action: 'action_view',
      data: Uri.encodeFull('geo:$lat,$lng?q=$lat,$lng'),
      package: 'com.google.android.apps.maps',
    );

    bool launched = false;
    try {
      await intent.launch();
      launched = true;
    } catch (e) {
      launched = false;
    }

    if (!launched && context?.mounted == true) {
      await _redirectToGoogleMapsPlayStore(context!);
    }
  }

  static Future<void> _launchiOSMaps(double lat, double lng) async {
    final url = Uri.parse('https://maps.apple.com/?q=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      final googleMapsUrl = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch any maps application');
      }
    }
  }

  static Future<void> _redirectToGoogleMapsPlayStore(BuildContext context) async {
    final playStoreIntent = AndroidIntent(
      action: 'action_view',
      data: Uri.encodeFull(
          'https://play.google.com/store/apps/details?id=com.google.android.apps.maps'),
    );
    await playStoreIntent.launch();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Redirecting to Google Maps download...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  static void _showErrorSnackBar(BuildContext context, dynamic e) {
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