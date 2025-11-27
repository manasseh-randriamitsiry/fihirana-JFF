import 'dart:io' show Platform;
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'ui_service.dart';

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
        UIService.showMapsErrorSnackBar(context!, e);
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
      UIService.showMapsRedirectSnackBar(context);
    }
  }


}