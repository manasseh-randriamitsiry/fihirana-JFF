import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:fihirana/features/contact/domain/entities/contact.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

enum _ContactAction { directions, edit, delete }

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
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final hasActions = onDirections != null || canEdit;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppGroupedSurface(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    contact.name.isNotEmpty
                        ? contact.name[0].toUpperCase()
                        : '?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _ContactDetail(
                        icon: Icons.phone_outlined,
                        text: contact.phoneNumber,
                      ),
                      if (contact.location != null &&
                          contact.location!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _ContactDetail(
                          icon: Icons.location_on_outlined,
                          text: contact.location!,
                        ),
                      ],
                    ],
                  ),
                ),
                if (hasActions)
                  PopupMenuButton<_ContactAction>(
                    tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                    icon: const Icon(Icons.more_horiz_rounded),
                    onSelected: (action) {
                      switch (action) {
                        case _ContactAction.directions:
                          onDirections?.call();
                        case _ContactAction.edit:
                          onEdit?.call();
                        case _ContactAction.delete:
                          onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      if (onDirections != null)
                        const PopupMenuItem(
                          value: _ContactAction.directions,
                          child: _ContactMenuItem(
                            icon: Icons.directions_rounded,
                            label: 'Itinéraire',
                          ),
                        ),
                      if (canEdit)
                        PopupMenuItem(
                          value: _ContactAction.edit,
                          child: _ContactMenuItem(
                            icon: Icons.edit_outlined,
                            label: l10n.edit,
                          ),
                        ),
                      if (canEdit)
                        PopupMenuItem(
                          value: _ContactAction.delete,
                          child: _ContactMenuItem(
                            icon: Icons.delete_outline_rounded,
                            label: l10n.delete,
                            color: colors.error,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 260.ms).slideY(begin: .06, end: 0);
  }
}

class _ContactDetail extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactDetail({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ContactMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _ContactMenuItem({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      children: [
        Icon(icon, size: 20, color: foreground),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: foreground)),
      ],
    );
  }
}

class ContactEmptyStateWidget extends StatelessWidget {
  const ContactEmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.perm_contact_calendar_rounded,
      title: AppLocalizations.of(context).noContactsFound,
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
    return AppSearchField(
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      onClear: () {
        controller.clear();
        onChanged('');
      },
    );
  }
}
