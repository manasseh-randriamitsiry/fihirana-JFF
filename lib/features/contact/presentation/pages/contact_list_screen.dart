import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/features/contact/domain/entities/contact.dart';
import 'package:fihirana/features/contact/domain/repositories/i_contact_service.dart';
import 'package:fihirana/core/utils/maps_launcher_service.dart';
import 'package:fihirana/features/contact/data/services/contact_import_service.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/navigation/context_aware_fab.dart';
import 'package:fihirana/features/contact/presentation/widgets/contact_picker_dialog_widget.dart';
import 'package:fihirana/features/contact/presentation/widgets/contact_import_dialog_widget.dart';
import 'package:fihirana/features/contact/presentation/widgets/contact_widgets.dart';
import 'package:fihirana/shared/widgets/common/confirm_delete_dialog.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  final IContactService _contactService = Get.find<IContactService>();
  final ColorController colorController = Get.find<ColorController>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchMaps(double lat, double lng) async {
    await MapsLauncherService.launchMaps(lat, lng, context: context);
  }

  Future<void> _importContact() async {
    final contacts = await ContactImportService.importContacts(context);
    if (contacts != null) {
      _showContactPickerDialog(contacts);
    }
  }

  void _showContactPickerDialog(List<flutter_contacts.Contact> contacts) {
    showDialog(
      context: context,
      builder: (context) => ContactImportDialogWidget(
        contacts: contacts,
        colorController: colorController,
        onContactSelected: (contactData) {
          showDialog(
            context: context,
            builder: (context) => ContactPickerDialog(
              colorController: colorController,
              importedContact: contactData,
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Contact contact) {
    final l10n = AppLocalizations.of(context)!;
    ConfirmDeleteDialog.show(
      context: context,
      colorController: colorController,
      title: l10n.delete,
      content: l10n.confirmDeleteContact,
      onConfirm: () async {
        final success = await _contactService.deleteContact(contact.id);
        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.deleted)),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.errorOccurred)),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorController.backgroundColor.value,
      appBar: AppBar(
        backgroundColor: colorController.backgroundColor.value,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.menu_rounded, color: colorController.iconColor.value),
          onPressed: () => Get.find<ShellController>().toggleDrawer(),
        ),
        title: Text(
          l10n.contacts,
          style: TextStyle(
            color: colorController.textColor.value,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: ContextAwareFAB(
        onImportContact: _importContact,
        onAddContact: () => showDialog(
          context: context,
          builder: (context) => ContactPickerDialog(
            colorController: colorController,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.md),
            child: ContactSearchWidget(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              hintText: l10n.searchContacts,
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Contact>>(
              stream: _contactService.getContactsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorController.primaryColor.value,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '${l10n.error}: ${snapshot.error}',
                      style: TextStyle(color: colorController.textColor.value),
                    ),
                  );
                }

                final contacts = snapshot.data ?? [];
                final filteredContacts = _searchQuery.isEmpty
                    ? contacts
                    : contacts.where((contact) {
                        return contact.name
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            contact.phoneNumber.contains(_searchQuery) ||
                            (contact.location
                                    ?.toLowerCase()
                                    .contains(_searchQuery) ??
                                false);
                      }).toList();

                if (filteredContacts.isEmpty) {
                  return const ContactEmptyStateWidget();
                }

                return ListView.builder(
                  key: const PageStorageKey('contacts_list'),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.md, vertical: AppDimensions.sm),
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    return FutureBuilder<bool>(
                      future: _contactService.canEditContact(contact),
                      builder: (context, permissionSnapshot) {
                        final canEdit = permissionSnapshot.data ?? false;

                        return ContactListItemWidget(
                          key: ValueKey(contact.id),
                          contact: contact,
                          canEdit: canEdit,
                          onDirections: (contact.latitude != null &&
                                  contact.longitude != null)
                              ? () => _launchMaps(
                                  contact.latitude!, contact.longitude!)
                              : null,
                          onEdit: canEdit
                              ? () => showDialog(
                                    context: context,
                                    builder: (context) => ContactPickerDialog(
                                      colorController: colorController,
                                      contact: contact,
                                    ),
                                  )
                              : null,
                          onDelete: canEdit
                              ? () => _confirmDelete(context, contact)
                              : null,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
