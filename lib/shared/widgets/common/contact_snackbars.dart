import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class ContactPermissionSnackBar {
  static void show(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.contactsPermissionRequired),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: l10n.settings,
          textColor: Colors.white,
          onPressed: () => openAppSettings(),
        ),
      ),
    );
  }
}

class NoContactsSnackBar {
  static void show(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.noContactsFound),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

class ContactsErrorSnackBar {
  static void show(BuildContext context, String error) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.errorAccessingContacts(error)),
        backgroundColor: Colors.red,
      ),
    );
  }
}