import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as maplibre;
import 'package:url_launcher/url_launcher.dart';
import '../../controller/color_controller.dart';
import '../../controller/shell_controller.dart';
import '../../models/contact.dart';
import '../../services/contact_service.dart';
import '../../l10n/app_localizations.dart';
import 'location_picker_screen.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  final ContactService _contactService = ContactService();
  final ColorController colorController = Get.find<ColorController>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchMaps(double lat, double lng) async {
    // Try Google Maps URL first
    final googleMapsUrl =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      return;
    }

    // Fallback to geo: URI which works with any map app
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');

    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      return;
    }

    // If both fail, show error message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No map app found. Please install Google Maps or another map application.')),
      );
    }
  }

  void _showAddEditContactDialog(BuildContext context, {Contact? contact}) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = contact != null;
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController =
        TextEditingController(text: contact?.phoneNumber ?? '');
    final locationController =
        TextEditingController(text: contact?.location ?? '');
    double? selectedLat = contact?.latitude;
    double? selectedLng = contact?.longitude;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: colorController.backgroundColor.value,
              title: Text(
                isEditing ? l10n.editContact : l10n.addContact,
                style: TextStyle(color: colorController.textColor.value),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: l10n.contactName,
                          labelStyle: TextStyle(
                              color: colorController.textColor.value
                                  .withValues(alpha: 0.7)),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorController.textColor.value
                                      .withValues(alpha: 0.3))),
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorController.primaryColor.value)),
                        ),
                        style:
                            TextStyle(color: colorController.textColor.value),
                        validator: (value) => value?.isEmpty ?? true
                            ? l10n.enterNamePlease
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: l10n.contactPhone,
                          labelStyle: TextStyle(
                              color: colorController.textColor.value
                                  .withValues(alpha: 0.7)),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorController.textColor.value
                                      .withValues(alpha: 0.3))),
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorController.primaryColor.value)),
                        ),
                        style:
                            TextStyle(color: colorController.textColor.value),
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                            value?.isEmpty ?? true ? l10n.fillAllFields : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: locationController,
                        decoration: InputDecoration(
                          labelText: l10n.contactLocation,
                          labelStyle: TextStyle(
                              color: colorController.textColor.value
                                  .withValues(alpha: 0.7)),
                          enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorController.textColor.value
                                      .withValues(alpha: 0.3))),
                          focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: colorController.primaryColor.value)),
                        ),
                        style:
                            TextStyle(color: colorController.textColor.value),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<maplibre.LatLng>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LocationPickerScreen(
                                initialLat: selectedLat,
                                initialLng: selectedLng,
                              ),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              selectedLat = result.latitude;
                              selectedLng = result.longitude;
                            });
                          }
                        },
                        icon: Icon(
                          Icons.map,
                          color: selectedLat != null
                              ? Colors.green
                              : colorController.primaryColor.value,
                        ),
                        label: Text(
                          selectedLat != null
                              ? 'Location Selected'
                              : 'Pick Location on Map',
                          style: TextStyle(
                            color: selectedLat != null
                                ? Colors.green
                                : colorController.primaryColor.value,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: selectedLat != null
                                ? Colors.green
                                : colorController.primaryColor.value,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel,
                      style: TextStyle(color: colorController.textColor.value)),
                ),
                TextButton(
                  onPressed: () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final success = isEditing
                          ? await _contactService
                              .updateContact(contact.copyWith(
                              name: nameController.text,
                              phoneNumber: phoneController.text,
                              location: locationController.text.isEmpty
                                  ? null
                                  : locationController.text,
                              latitude: selectedLat,
                              longitude: selectedLng,
                            ))
                          : await _contactService.addContact(
                              name: nameController.text,
                              phoneNumber: phoneController.text,
                              location: locationController.text.isEmpty
                                  ? null
                                  : locationController.text,
                              latitude: selectedLat,
                              longitude: selectedLng,
                            );

                      if (context.mounted) {
                        Navigator.pop(context);
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.contactSaved)),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.errorOccurred)),
                          );
                        }
                      }
                    }
                  },
                  child: Text(l10n.save,
                      style:
                          TextStyle(color: colorController.primaryColor.value)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Contact contact) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorController.backgroundColor.value,
        title: Text(l10n.delete,
            style: TextStyle(color: colorController.textColor.value)),
        content: Text(l10n.confirmDeleteContact,
            style: TextStyle(color: colorController.textColor.value)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel,
                style: TextStyle(color: colorController.textColor.value)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
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
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditContactDialog(context),
        backgroundColor: colorController.primaryColor.value,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: colorController.backgroundColor.value,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorController.textColor.value.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: l10n.searchContacts,
                  hintStyle: TextStyle(
                    color:
                        colorController.iconColor.value.withValues(alpha: 0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colorController.iconColor.value,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: colorController.iconColor.value,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: TextStyle(
                  color: colorController.textColor.value,
                ),
              ),
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.perm_contact_calendar_rounded,
                          size: 80,
                          color: colorController.textColor.value
                              .withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noContactsFound,
                          style: TextStyle(
                            color: colorController.textColor.value,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = filteredContacts[index];
                    return FutureBuilder<bool>(
                      future: _contactService.canEditContact(contact),
                      builder: (context, permissionSnapshot) {
                        final canEdit = permissionSnapshot.data ?? false;

                        return Card(
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: colorController.textColor.value
                                  .withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          color: colorController.backgroundColor.value,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: colorController
                                  .primaryColor.value
                                  .withValues(alpha: 0.15),
                              child: Text(
                                contact.name.isNotEmpty
                                    ? contact.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: colorController.primaryColor.value,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              contact.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colorController.textColor.value,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.phone,
                                        size: 14,
                                        color: colorController.iconColor.value
                                            .withValues(alpha: 0.7)),
                                    const SizedBox(width: 4),
                                    Text(
                                      contact.phoneNumber,
                                      style: TextStyle(
                                        color: colorController.textColor.value
                                            .withValues(alpha: 0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                if (contact.location != null &&
                                    contact.location!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                          size: 14,
                                          color: colorController.iconColor.value
                                              .withValues(alpha: 0.7)),
                                      const SizedBox(width: 4),
                                      Text(
                                        contact.location!,
                                        style: TextStyle(
                                          color: colorController.textColor.value
                                              .withValues(alpha: 0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (contact.latitude != null &&
                                    contact.longitude != null)
                                  IconButton(
                                    icon: const Icon(Icons.directions,
                                        color: Colors.blue),
                                    onPressed: () => _launchMaps(
                                        contact.latitude!, contact.longitude!),
                                    tooltip: 'Directions',
                                  ),
                                if (canEdit) ...[
                                  IconButton(
                                    icon: Icon(Icons.edit,
                                        color: colorController.iconColor.value),
                                    onPressed: () => _showAddEditContactDialog(
                                        context,
                                        contact: contact),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _confirmDelete(context, contact),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .slideY(begin: 0.1, end: 0);
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
