import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as maplibre;
import 'package:url_launcher/url_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;
import 'package:permission_handler/permission_handler.dart';
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
  bool _isFABExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchMaps(double lat, double lng) async {
    try {
      if (Platform.isAndroid) {
        // First try to launch Google Maps directly
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

        // If Google Maps is not installed, redirect to Play Store
        if (!launched) {
          final playStoreIntent = AndroidIntent(
            action: 'action_view',
            data: Uri.encodeFull(
                'https://play.google.com/store/apps/details?id=com.google.android.apps.maps'),
          );
          await playStoreIntent.launch();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Redirecting to Google Maps download...'),
                backgroundColor: colorController.primaryColor.value,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // iOS: Use URL launcher
        final url = Uri.parse('https://maps.apple.com/?q=$lat,$lng');
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          // Fallback to Google Maps web if Apple Maps fails
          final googleMapsUrl =
              Uri.parse('https://www.google.com/maps?q=$lat,$lng');
          if (await canLaunchUrl(googleMapsUrl)) {
            await launchUrl(googleMapsUrl,
                mode: LaunchMode.externalApplication);
          } else {
            throw Exception('Could not launch any maps application');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Could not open maps. Please install a maps application.'),
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
                    await launchUrl(appStoreUrl,
                        mode: LaunchMode.externalApplication);
                  }
                }
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _importContact() async {
    // Request contacts permission
    final status = await Permission.contacts.request();

    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Contacts permission is required to import contacts.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    try {
      // Get all contacts
      final contacts = await flutter_contacts.FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      if (contacts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No contacts found on your device.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Show contact picker dialog
      _showContactPickerDialog(contacts);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing contacts: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showContactPickerDialog(List<flutter_contacts.Contact> contacts) {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final searchQuery = searchController.text.toLowerCase();
          final filteredContacts = searchQuery.isEmpty
              ? contacts
              : contacts.where((contact) {
                  final name = contact.displayName.toLowerCase();
                  final phone = contact.phones.isNotEmpty
                      ? contact.phones.first.number
                      : '';
                  return name.contains(searchQuery) ||
                      phone.contains(searchQuery);
                }).toList();

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Container(
              decoration: BoxDecoration(
                color: colorController.backgroundColor.value,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorController.primaryColor.value
                          .withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.contacts_rounded,
                          color: colorController.primaryColor.value,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Select Contact',
                            style: TextStyle(
                              color: colorController.textColor.value,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: colorController.iconColor.value,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorController.backgroundColor.value,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorController.textColor.value
                              .withValues(alpha: 0.1),
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
                        controller: searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search contacts...',
                          hintStyle: TextStyle(
                            color: colorController.iconColor.value
                                .withValues(alpha: 0.5),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorController.iconColor.value,
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: colorController.iconColor.value,
                                  ),
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        style: TextStyle(
                          color: colorController.textColor.value,
                        ),
                      ),
                    ),
                  ),

                  // Contact List
                  Flexible(
                    child: filteredContacts.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: colorController.textColor.value
                                        .withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No contacts found',
                                    style: TextStyle(
                                      color: colorController.textColor.value,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: filteredContacts.length,
                            itemBuilder: (context, index) {
                              final contact = filteredContacts[index];
                              final displayName = contact.displayName;
                              final phoneNumber = contact.phones.isNotEmpty
                                  ? contact.phones.first.number
                                  : '';

                              return Card(
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: colorController.textColor.value
                                        .withValues(alpha: 0.1),
                                    width: 1,
                                  ),
                                ),
                                color: colorController.backgroundColor.value,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _showAddEditContactDialog(
                                      context,
                                      contact: null,
                                      importedContact: {
                                        'name': displayName,
                                        'phone': phoneNumber,
                                      },
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: colorController
                                              .primaryColor.value
                                              .withValues(alpha: 0.15),
                                          radius: 24,
                                          child: Text(
                                            displayName.isNotEmpty
                                                ? displayName[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              color: colorController
                                                  .primaryColor.value,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                displayName,
                                                style: TextStyle(
                                                  color: colorController
                                                      .textColor.value,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (phoneNumber.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.phone,
                                                      size: 14,
                                                      color: colorController
                                                          .iconColor.value
                                                          .withValues(
                                                              alpha: 0.7),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      phoneNumber,
                                                      style: TextStyle(
                                                        color: colorController
                                                            .textColor.value
                                                            .withValues(
                                                                alpha: 0.7),
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: colorController.iconColor.value
                                              .withValues(alpha: 0.3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(duration: 200.ms).slideX(
                                    begin: 0.1,
                                    end: 0,
                                    duration: 200.ms,
                                  );
                            },
                          ),
                  ),

                  // Bottom padding
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      searchController.dispose();
    });
  }

  void _showAddEditContactDialog(BuildContext context,
      {Contact? contact, Map<String, String>? importedContact}) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = contact != null;
    final nameController = TextEditingController(
        text: importedContact?['name'] ?? contact?.name ?? '');
    final phoneController = TextEditingController(
        text: importedContact?['phone'] ?? contact?.phoneNumber ?? '');
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

  Widget _buildSpeedDialFAB() {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        // Backdrop overlay when expanded
        if (_isFABExpanded)
          GestureDetector(
            onTap: () {
              setState(() {
                _isFABExpanded = false;
              });
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ).animate().fadeIn(duration: 200.ms),

        // Speed dial action buttons and main FAB
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action buttons (shown when expanded)
            if (_isFABExpanded) ...[
              // Import Contact Button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorController.backgroundColor.value,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Import Contact',
                      style: TextStyle(
                        color: colorController.textColor.value,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    heroTag: "importContact",
                    mini: true,
                    onPressed: () {
                      setState(() {
                        _isFABExpanded = false;
                      });
                      _importContact();
                    },
                    backgroundColor: colorController.primaryColor.value
                        .withValues(alpha: 0.8),
                    elevation: 4,
                    child: const Icon(
                      Icons.contacts,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 200.ms, delay: 50.ms)
                  .slideX(begin: -0.2, end: 0, duration: 200.ms, delay: 50.ms),

              const SizedBox(height: 12),

              // Add Contact Button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colorController.backgroundColor.value,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Add Contact',
                      style: TextStyle(
                        color: colorController.textColor.value,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    heroTag: "addContact",
                    mini: true,
                    onPressed: () {
                      setState(() {
                        _isFABExpanded = false;
                      });
                      _showAddEditContactDialog(context);
                    },
                    backgroundColor: colorController.primaryColor.value,
                    elevation: 4,
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 200.ms, delay: 100.ms)
                  .slideX(begin: -0.2, end: 0, duration: 200.ms, delay: 100.ms),

              const SizedBox(height: 16),
            ],

            // Main FAB
            FloatingActionButton(
              heroTag: "mainFAB",
              onPressed: () {
                setState(() {
                  _isFABExpanded = !_isFABExpanded;
                });
              },
              backgroundColor: colorController.primaryColor.value,
              elevation: 6,
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: _isFABExpanded ? 0.125 : 0, // 45 degrees when expanded
                child: Icon(
                  _isFABExpanded ? Icons.close : Icons.add,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
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
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: _buildSpeedDialFAB(),
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
