import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/color_controller.dart';

class AdminStatTileWidget extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const AdminStatTileWidget({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    final textColor = colorController.textColor.value;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class AdminStatsRowWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const AdminStatsRowWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AdminStatTileWidget(
            title: 'Users',
            value: '${stats['totalUsers']}',
            subtitle: '${stats['activeUsers']} active',
            icon: Icons.people,
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          AdminStatTileWidget(
            title: 'Hymns',
            value: '${stats['totalHymns']}',
            subtitle: 'Total added',
            icon: Icons.library_music,
            color: Colors.orange,
          ),
          const SizedBox(width: 12),
          AdminStatTileWidget(
            title: 'Installs',
            value: '${stats['installations']}',
            subtitle: 'All time',
            icon: Icons.download,
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}