import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/admin/presentation/controllers/admin_controller.dart';
import 'package:fihirana/features/admin/di/admin_di.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';

/// Simplified admin dashboard widget using clean architecture
class AdminDashboardWidget extends StatelessWidget {
  const AdminDashboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ColorController colorController = Get.find<ColorController>();
    final AdminController adminController = AdminDI.adminController;

    return Obx(() {
      final backgroundColor = colorController.backgroundColor.value;
      final textColor = colorController.textColor.value;
      final primaryColor = colorController.primaryColor.value;

      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Admin Dashboard',
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Stats Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard(
                    context,
                    title: 'Total Users',
                    value: adminController.adminStats.value?.totalUsers.toString() ?? '0',
                    icon: Icons.people,
                    color: Colors.blue,
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Active Users',
                    value: adminController.adminStats.value?.activeUsers.toString() ?? '0',
                    icon: Icons.person_pin,
                    color: Colors.green,
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Total Hymns',
                    value: adminController.adminStats.value?.totalHymns.toString() ?? '0',
                    icon: Icons.music_note,
                    color: Colors.purple,
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Installations',
                    value: adminController.adminStats.value?.installations.toString() ?? '0',
                    icon: Icons.download,
                    color: Colors.orange,
                    textColor: textColor,
                    backgroundColor: backgroundColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Actions
            _buildQuickActionsSection(
              context,
              adminController,
              l10n,
              textColor,
              primaryColor,
              backgroundColor,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(
    BuildContext context,
    AdminController adminController,
    AppLocalizations l10n,
    Color textColor,
    Color primaryColor,
    Color backgroundColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                title: 'Refresh Data',
                icon: Icons.refresh,
                color: Colors.blue,
                onPressed: adminController.refresh,
                textColor: textColor,
                backgroundColor: backgroundColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                title: 'Export Users',
                icon: Icons.download,
                color: Colors.green,
                onPressed: () => _exportUsers(context, adminController, l10n),
                textColor: textColor,
                backgroundColor: backgroundColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _exportUsers(
    BuildContext context,
    AdminController adminController,
    AppLocalizations l10n,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feature coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}