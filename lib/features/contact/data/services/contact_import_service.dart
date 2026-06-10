import 'package:flutter/widgets.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;
import 'package:permission_handler/permission_handler.dart';
import 'package:fihirana/core/utils/ui_service.dart';

class ContactImportService {
  static Future<List<flutter_contacts.Contact>?> importContacts(
      BuildContext context) async {
    final status = await Permission.contacts.request();

    if (!status.isGranted) {
      if (context.mounted) {
        UIService.showContactPermissionSnackBar(context);
      }
      return null;
    }

    try {
      final contacts = await flutter_contacts.FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      if (contacts.isEmpty) {
        if (context.mounted) {
          UIService.showNoContactsSnackBar(context);
        }
        return null;
      }

      return contacts;
    } catch (e) {
      if (context.mounted) {
        UIService.showContactsErrorSnackBar(context, e.toString());
      }
      return null;
    }
  }
}
