import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;
import 'package:permission_handler/permission_handler.dart';

class ContactImportService {
  static Future<List<flutter_contacts.Contact>?> importContacts(BuildContext context) async {
    final status = await Permission.contacts.request();

    if (!status.isGranted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Contacts permission is required to import contacts.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No contacts found on your device.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }

      return contacts;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing contacts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
}