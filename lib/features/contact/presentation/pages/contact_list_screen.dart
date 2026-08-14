import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;
import 'package:get/get.dart';

import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/core/navigation/shell_controller.dart';
import 'package:fihirana/core/utils/maps_launcher_service.dart';
import 'package:fihirana/features/contact/data/services/contact_import_service.dart';
import 'package:fihirana/features/contact/domain/entities/contact.dart';
import 'package:fihirana/features/contact/domain/repositories/i_contact_service.dart';
import 'package:fihirana/features/contact/presentation/widgets/contact_import_dialog_widget.dart';
import 'package:fihirana/features/contact/presentation/widgets/contact_picker_dialog_widget.dart';
import 'package:fihirana/features/contact/presentation/widgets/contact_widgets.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';
import 'package:fihirana/shared/widgets/common/confirm_delete_dialog.dart';
import 'package:fihirana/shared/widgets/navigation/context_aware_fab.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  final IContactService _contactService = Get.find<IContactService>();
  final ColorController colorController = Get.find<ColorController>();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _editPermissionCache = {};
  Timer? _searchDebounce;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchMaps(double lat, double lng) async {
    await MapsLauncherService.launchMaps(lat, lng, context: context);
  }

  Future<void> _importContact() async {
    final contacts = await ContactImportService.importContacts(context);
    if (contacts != null) _showContactPickerDialog(contacts);
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
    final l10n = AppLocalizations.of(context);
    ConfirmDeleteDialog.show(
      context: context,
      colorController: colorController,
      title: l10n.delete,
      content: l10n.confirmDeleteContact,
      onConfirm: () async {
        final success = await _contactService.deleteContact(contact.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success ? l10n.deleted : l10n.errorOccurred)),
        );
      },
    );
  }

  void _onSearchChanged(String value) {
    // Rebuild immediately to keep the search affordance responsive, then
    // debounce the potentially larger filtered list.
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _searchQuery = value.toLowerCase());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;

    return AppPageScaffold(
      title: l10n.contacts,
      leading: IconButton(
        tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        icon: const Icon(Icons.menu_rounded),
        onPressed: Get.find<ShellController>().toggleDrawer,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: AppSearchField(
                  controller: _searchController,
                  hintText: l10n.searchContacts,
                  onChanged: _onSearchChanged,
                  onClear: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Contact>>(
                  stream: _contactService.getContactsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: colors.primary),
                      );
                    }
                    if (snapshot.hasError) {
                      return AppEmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: l10n.error,
                        message: snapshot.error.toString(),
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
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                      itemCount: filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = filteredContacts[index];
                        final cachedCanEdit = _editPermissionCache[contact.id];
                        return FutureBuilder<bool>(
                          future: cachedCanEdit == null
                              ? _contactService.canEditContact(contact)
                              : Future<bool>.value(cachedCanEdit),
                          builder: (context, permissionSnapshot) {
                            final canEdit = permissionSnapshot.data ?? false;
                            if (permissionSnapshot.hasData) {
                              _editPermissionCache[contact.id] = canEdit;
                            }
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
                                        builder: (context) =>
                                            ContactPickerDialog(
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
          Positioned(
            right: 16,
            bottom: 16,
            child: ContextAwareFAB(
              onImportContact: _importContact,
              onAddContact: () => showDialog(
                context: context,
                builder: (context) => ContactPickerDialog(
                  colorController: colorController,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
