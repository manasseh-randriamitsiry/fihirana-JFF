import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class ContactImportDialogWidget extends StatefulWidget {
  final List<flutter_contacts.Contact> contacts;
  final ColorController colorController;
  final Function(Map<String, String>) onContactSelected;

  const ContactImportDialogWidget({
    super.key,
    required this.contacts,
    required this.colorController,
    required this.onContactSelected,
  });

  @override
  State<ContactImportDialogWidget> createState() =>
      _ContactImportDialogWidgetState();
}

class _ContactImportDialogWidgetState extends State<ContactImportDialogWidget> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<flutter_contacts.Contact> get _filteredContacts {
    final searchQuery = _searchController.text.toLowerCase();
    return searchQuery.isEmpty
        ? widget.contacts
        : widget.contacts.where((contact) {
            final name = contact.displayName.toLowerCase();
            final phone =
                contact.phones.isNotEmpty ? contact.phones.first.number : '';
            return name.contains(searchQuery) || phone.contains(searchQuery);
          }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: widget.colorController.backgroundColor.value,
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
            _buildHeader(),
            _buildSearchBar(),
            _buildContactList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.colorController.primaryColor.value.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.contacts_rounded,
            color: widget.colorController.primaryColor.value,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sélectionner un contact',
              style: TextStyle(
                color: widget.colorController.textColor.value,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: widget.colorController.iconColor.value,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: widget.colorController.backgroundColor.value,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                widget.colorController.textColor.value.withValues(alpha: 0.1),
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
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).searchContacts,
            hintStyle: TextStyle(
              color:
                  widget.colorController.iconColor.value.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: widget.colorController.iconColor.value,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: widget.colorController.iconColor.value,
                    ),
                    onPressed: () {
                      _searchController.clear();
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
            color: widget.colorController.textColor.value,
          ),
        ),
      ),
    );
  }

  Widget _buildContactList() {
    return Flexible(
      child: _filteredContacts.isEmpty
          ? _buildEmptyState()
          : _buildContactListView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color:
                  widget.colorController.textColor.value.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun contact trouvé',
              style: TextStyle(
                color: widget.colorController.textColor.value,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactListView() {
    return ListView.builder(
      key: const PageStorageKey('import_contacts_list'),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        final displayName = contact.displayName;
        final phoneNumber =
            contact.phones.isNotEmpty ? contact.phones.first.number : '';

        return Card(
          key: ValueKey(displayName + phoneNumber),
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color:
                  widget.colorController.textColor.value.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          color: widget.colorController.backgroundColor.value,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.pop(context);
              widget.onContactSelected({
                'name': displayName,
                'phone': phoneNumber,
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: widget.colorController.primaryColor.value
                        .withValues(alpha: 0.15),
                    radius: 24,
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: widget.colorController.primaryColor.value,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            color: widget.colorController.textColor.value,
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
                                color: widget.colorController.iconColor.value
                                    .withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                phoneNumber,
                                style: TextStyle(
                                  color: widget.colorController.textColor.value
                                      .withValues(alpha: 0.7),
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
                    color: widget.colorController.iconColor.value
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
    );
  }
}
