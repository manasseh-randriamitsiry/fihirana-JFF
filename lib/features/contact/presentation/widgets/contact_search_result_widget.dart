import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;
import 'package:fihirana/app/theme/color_controller.dart';

class ContactSearchResultWidget extends StatelessWidget {
  final flutter_contacts.Contact contact;
  final ColorController colorController;
  final VoidCallback onTap;

  const ContactSearchResultWidget({
    super.key,
    required this.contact,
    required this.colorController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          color: colorController.textColor.value.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      color: colorController.backgroundColor.value,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorController.primaryColor.value.withValues(alpha: 0.15),
                radius: 24,
                child: Text(
                  displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: colorController.primaryColor.value,
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
                        color: colorController.textColor.value,
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
                            color: colorController.iconColor.value.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            phoneNumber,
                            style: TextStyle(
                              color: colorController.textColor.value.withValues(alpha: 0.7),
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
                color: colorController.iconColor.value.withValues(alpha: 0.3),
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
  }
}