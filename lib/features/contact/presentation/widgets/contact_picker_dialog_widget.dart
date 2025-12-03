import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as maplibre;

import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/features/contact/domain/entities/contact.dart';
import 'package:fihirana/features/contact/data/services/contact_service.dart';
import 'package:fihirana/features/contact/presentation/pages/location_picker_screen.dart';

class ContactPickerDialog extends StatefulWidget {
  final ColorController colorController;
  final Contact? contact;
  final Map<String, String>? importedContact;

  const ContactPickerDialog({
    super.key,
    required this.colorController,
    this.contact,
    this.importedContact,
  });

  @override
  State<ContactPickerDialog> createState() => _ContactPickerDialogState();
}

class _ContactPickerDialogState extends State<ContactPickerDialog> {
  final ContactService _contactService = ContactService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  double? _selectedLat;
  double? _selectedLng;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.importedContact?['name'] ?? widget.contact?.name ?? '');
    _phoneController = TextEditingController(
        text: widget.importedContact?['phone'] ??
            widget.contact?.phoneNumber ??
            '');
    _locationController =
        TextEditingController(text: widget.contact?.location ?? '');
    _selectedLat = widget.contact?.latitude;
    _selectedLng = widget.contact?.longitude;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.contact != null;

    return AlertDialog(
      backgroundColor: widget.colorController.backgroundColor.value,
      title: Text(
        isEditing ? l10n.editContact : l10n.addContact,
        style: TextStyle(color: widget.colorController.textColor.value),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.contactName,
                  labelStyle: TextStyle(
                      color: widget.colorController.textColor.value
                          .withValues(alpha: 0.7)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: widget.colorController.textColor.value
                              .withValues(alpha: 0.3))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: widget.colorController.primaryColor.value)),
                ),
                style: TextStyle(color: widget.colorController.textColor.value),
                validator: (value) =>
                    value?.isEmpty ?? true ? l10n.enterNamePlease : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: l10n.contactPhone,
                  labelStyle: TextStyle(
                      color: widget.colorController.textColor.value
                          .withValues(alpha: 0.7)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: widget.colorController.textColor.value
                              .withValues(alpha: 0.3))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: widget.colorController.primaryColor.value)),
                ),
                style: TextStyle(color: widget.colorController.textColor.value),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value?.isEmpty ?? true ? l10n.fillAllFields : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: l10n.contactLocation,
                  labelStyle: TextStyle(
                      color: widget.colorController.textColor.value
                          .withValues(alpha: 0.7)),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: widget.colorController.textColor.value
                              .withValues(alpha: 0.3))),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                          color: widget.colorController.primaryColor.value)),
                ),
                style: TextStyle(color: widget.colorController.textColor.value),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<maplibre.LatLng>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationPickerScreen(
                        initialLat: _selectedLat,
                        initialLng: _selectedLng,
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _selectedLat = result.latitude;
                      _selectedLng = result.longitude;
                    });
                  }
                },
                icon: Icon(
                  Icons.map,
                  color: _selectedLat != null
                      ? Colors.green
                      : widget.colorController.primaryColor.value,
                ),
                label: Text(
                  _selectedLat != null
                      ? 'Location Selected'
                      : 'Pick Location on Map',
                  style: TextStyle(
                    color: _selectedLat != null
                        ? Colors.green
                        : widget.colorController.primaryColor.value,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _selectedLat != null
                        ? Colors.green
                        : widget.colorController.primaryColor.value,
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
              style: TextStyle(color: widget.colorController.textColor.value)),
        ),
        TextButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              final success = isEditing
                  ? await _contactService
                      .updateContact(widget.contact!.copyWith(
                      name: _nameController.text,
                      phoneNumber: _phoneController.text,
                      location: _locationController.text.isEmpty
                          ? null
                          : _locationController.text,
                      latitude: _selectedLat,
                      longitude: _selectedLng,
                    ))
                  : await _contactService.addContact(
                      name: _nameController.text,
                      phoneNumber: _phoneController.text,
                      location: _locationController.text.isEmpty
                          ? null
                          : _locationController.text,
                      latitude: _selectedLat,
                      longitude: _selectedLng,
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
                  TextStyle(color: widget.colorController.primaryColor.value)),
        ),
      ],
    );
  }
}
