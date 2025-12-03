import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/admin/domain/entities/admin_user.dart';
import 'package:fihirana/features/admin/presentation/controllers/admin_controller.dart';
import 'package:fihirana/features/admin/di/admin_di.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/skeleton_admin_list.dart';

/// Simplified user management screen using clean architecture
class UserManagementScreenClean extends StatelessWidget {
  const UserManagementScreenClean({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ColorController colorController = Get.find<ColorController>();
    final AdminController adminController = AdminDI.adminController;

    return Obx(() {
      final backgroundColor = colorController.backgroundColor.value;
      final textColor = colorController.textColor.value;
      final primaryColor = colorController.primaryColor.value;

      return Scaffold(
        backgroundColor: backgroundColor,
        body: Column(
          children: [
            // Search Section
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                onChanged: adminController.searchUsers,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: Icon(Icons.search, color: textColor.withValues(alpha: 0.6)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: textColor.withValues(alpha: 0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: textColor.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
                style: TextStyle(color: textColor),
              ),
            ),

            // Users List
            Expanded(
              child: _buildUsersList(
                context,
                adminController,
                l10n,
                textColor,
                primaryColor,
                backgroundColor,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildUsersList(
    BuildContext context,
    AdminController adminController,
    AppLocalizations l10n,
    Color textColor,
    Color primaryColor,
    Color backgroundColor,
  ) {
    return Obx(() {
      if (adminController.isLoadingUsers.value) {
        return const SkeletonAdminList();
      }

      if (adminController.errorMessage.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: textColor.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                adminController.errorMessage.value,
                style: TextStyle(color: textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: adminController.refresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      }

      final users = adminController.filteredUsers;

      if (users.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: textColor.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'No users found',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: adminController.refresh,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _UserListItem(
              user: user,
              isSelected: adminController.isUserSelected(user.id),
              onSelectionChanged: (selected) {
                adminController.toggleUserSelection(user.id);
              },
              onToggleAdmin: () => _toggleUserAdmin(context, adminController, user),
              onToggleBlock: () => _toggleUserBlock(context, adminController, user),
              onDelete: () => _deleteUser(context, adminController, user),
              textColor: textColor,
              primaryColor: primaryColor,
              backgroundColor: backgroundColor,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isAdmin ? 'Revoke Admin Access' : 'Grant Admin Access'),
        content: Text(
          user.isAdmin
              ? 'Are you sure you want to revoke admin access from ${user.displayName}?'
              : 'Are you sure you want to grant admin access to ${user.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await adminController.updateUserAdminStatus(user.id, !user.isAdmin);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(user.isAdmin 
                        ? 'Admin access revoked'
                        : 'Admin access granted'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isBlocked ? 'Unblock User' : 'Block User'),
        content: Text(
          user.isBlocked
              ? 'Are you sure you want to unblock ${user.displayName}?'
              : 'Are you sure you want to block ${user.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await adminController.blockUser(user.id, !user.isBlocked);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(user.isBlocked 
                        ? 'User unblocked'
                        : 'User blocked'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.displayName}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await adminController.deleteUser(user.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
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
  final Color textColor;
  final Color primaryColor;
  final Color backgroundColor;

  const _UserListItem({
    required this.user,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.onToggleAdmin,
    required this.onToggleBlock,
    required this.onDelete,
    required this.textColor,
    required this.primaryColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: onSelectionChanged,
          activeColor: primaryColor,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.displayName,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (user.isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (user.isBlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'BLOCKED',
                  style: TextStyle(
                    color: Colors.white,
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
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last login: ${user.lastLogin != null ? _formatDate(user.lastLogin!) : 'Never'}',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: textColor),
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
            PopupMenuItem(
              value: 'toggle_admin',
              child: Text(user.isAdmin ? 'Revoke Admin' : 'Make Admin'),
            ),
            PopupMenuItem(
              value: 'toggle_block',
              child: Text(user.isBlocked ? 'Unblock User' : 'Block User'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete User', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}