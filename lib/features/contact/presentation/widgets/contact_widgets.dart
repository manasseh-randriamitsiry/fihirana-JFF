import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/contact/domain/entities/contact.dart';
import 'package:fihirana/app/theme/color_controller.dart';

class ContactListItemWidget extends StatelessWidget {
  final Contact contact;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDirections;

  const ContactListItemWidget({
    super.key,
    required this.contact,
    required this.canEdit,
    this.onEdit,
    this.onDelete,
    this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorController.textColor.value.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      color: colorController.backgroundColor.value,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              colorController.primaryColor.value.withValues(alpha: 0.15),
          child: Text(
            contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
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
                    color:
                        colorController.iconColor.value.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  contact.phoneNumber,
                  style: TextStyle(
                    color:
                        colorController.textColor.value.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (contact.location != null && contact.location!.isNotEmpty) ...[
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
            if (contact.latitude != null && contact.longitude != null)
              IconButton(
                icon: const Icon(Icons.directions, color: Colors.blue),
                onPressed: onDirections,
                tooltip: 'Directions',
              ),
            if (canEdit) ...[
              IconButton(
                icon: Icon(Icons.edit, color: colorController.iconColor.value),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

class ContactEmptyStateWidget extends StatelessWidget {
  const ContactEmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.perm_contact_calendar_rounded,
            size: 80,
            color: colorController.textColor.value.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No contacts found',
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
}

class ContactSearchWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  const ContactSearchWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return Container(
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
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: colorController.iconColor.value.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: colorController.iconColor.value,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: colorController.iconColor.value,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
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
    );
  }
}
