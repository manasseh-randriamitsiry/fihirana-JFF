import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactPermissionSnackBar {
  static void show(BuildContext context) {
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
}

class NoContactsSnackBar {
  static void show(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No contacts found on your device.'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

class ContactsErrorSnackBar {
  static void show(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error accessing contacts: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }
}