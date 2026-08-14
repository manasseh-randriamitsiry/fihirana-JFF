import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/admin/domain/entities/admin_user.dart';
import 'package:fihirana/features/admin/presentation/controllers/admin_controller.dart';
import 'package:fihirana/features/admin/di/admin_di.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/skeleton_admin_list.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AdminController adminController = AdminDI.adminController;
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: TextField(
            onChanged: adminController.searchUsers,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.searchUsersHint,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: .6),
            ),
          ),
        ),
        Expanded(child: _buildUsersList(context, adminController, l10n)),
      ],
    );
  }

  Widget _buildUsersList(
    BuildContext context,
    AdminController adminController,
    AppLocalizations l10n,
  ) {
    return Obx(() {
      if (adminController.isLoadingUsers.value) {
        return const SkeletonAdminList();
      }

      if (adminController.errorMessage.value.isNotEmpty) {
        return AppEmptyState(
          icon: Icons.error_outline_rounded,
          title: l10n.error,
          message: adminController.errorMessage.value,
          action: FilledButton(
            onPressed: adminController.refresh,
            child: Text(l10n.retry),
          ),
        );
      }

      final users = adminController.filteredUsers;

      if (users.isEmpty) {
        return AppEmptyState(
          icon: Icons.people_outline_rounded,
          title: l10n.noUsersFound,
        );
      }

      return RefreshIndicator(
        onRefresh: adminController.refresh,
        child: ListView.builder(
          key: const PageStorageKey('users_list'),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _UserListItem(
              key: ValueKey(user.id),
              user: user,
              isSelected: adminController.isUserSelected(user.id),
              onSelectionChanged: (selected) {
                adminController.toggleUserSelection(user.id);
              },
              onToggleAdmin: () =>
                  _toggleUserAdmin(context, adminController, user),
              onToggleBlock: () =>
                  _toggleUserBlock(context, adminController, user),
              onDelete: () => _deleteUser(context, adminController, user),
            );
          },
        ),
      );
    });
  }

  void _toggleUserAdmin(
    BuildContext context,
    AdminController adminController,
    AdminUser user,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(user.isAdmin ? l10n.revokeAdminAccess : l10n.grantAdminAccess),
        content: Text(
          user.isAdmin
              ? l10n.confirmRevokeAdminAccess(user.displayName)
              : l10n.confirmGrantAdminAccess(user.displayName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await adminController.updateUserAdminStatus(
                  user.id, !user.isAdmin);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(user.isAdmin
                        ? l10n.adminAccessRevoked
                        : l10n.adminAccessGranted),
                  ),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _toggleUserBlock(
    BuildContext context,
    AdminController adminController,
    AdminUser user,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isBlocked ? l10n.unblockUser : l10n.blockUser),
        content: Text(
          user.isBlocked
              ? l10n.confirmUnblockUser(user.displayName)
              : l10n.confirmBlockUser(user.displayName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success =
                  await adminController.blockUser(user.id, !user.isBlocked);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        user.isBlocked ? l10n.userUnblocked : l10n.userBlocked),
                  ),
                );
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(
    BuildContext context,
    AdminController adminController,
    AdminUser user,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer l'utilisateur"),
        content: Text(
          l10n.confirmDeleteUser(user.displayName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await adminController.deleteUser(user.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.userDeletedSuccessfully),
                  ),
                );
              }
            },
            child: Text('Supprimer',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

class _UserListItem extends StatelessWidget {
  final AdminUser user;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectionChanged;
  final VoidCallback onToggleAdmin;
  final VoidCallback onToggleBlock;
  final VoidCallback onDelete;

  const _UserListItem({
    super.key,
    required this.user,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onToggleAdmin,
    required this.onToggleBlock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppGroupedSurface(
        children: [
          ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: onSelectionChanged,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    user.displayName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (user.isAdmin)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Administrateur',
                      style: TextStyle(
                        color: colors.onSecondaryContainer,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (user.isBlocked)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Bloqué',
                      style: TextStyle(
                        color: colors.onErrorContainer,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  "Dernière connexion : ${user.lastLogin != null ? _formatDate(user.lastLogin!, context) : 'Jamais'}",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (action) {
                switch (action) {
                  case 'toggle_admin':
                    onToggleAdmin();
                    break;
                  case 'toggle_block':
                    onToggleBlock();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'toggle_admin',
                  child: Text('Gérer les droits administrateur'),
                ),
                PopupMenuItem(
                  value: 'toggle_block',
                  child: Text(user.isBlocked ? 'Débloquer' : 'Bloquer'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child:
                      Text('Supprimer', style: TextStyle(color: colors.error)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return AppLocalizations.of(context).daysAgo(difference.inDays);
    } else if (difference.inHours > 0) {
      return AppLocalizations.of(context).hoursAgo(difference.inHours);
    } else if (difference.inMinutes > 0) {
      return AppLocalizations.of(context).minutesAgo(difference.inMinutes);
    } else {
      return AppLocalizations.of(context).justNow;
    }
  }
}
