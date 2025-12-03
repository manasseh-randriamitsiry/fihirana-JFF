import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';

class HistoryItemCard extends StatelessWidget {
  final Map<String, dynamic> history;
  final int index;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool?>? onSelectionChanged;

  const HistoryItemCard({
    super.key,
    required this.history,
    required this.index,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    
    final DateTime timestamp = history['timestamp'];
    final String formattedDate = 
        '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: colorController.backgroundColor.value,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: colorController.primaryColor.value,
            radius: 25,
            child: Text(
              '${history['number']}',
              style: TextStyle(
                color: colorController.backgroundColor.value,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            history['title'] ?? 'Hira ${history['number']}',
            style: TextStyle(
              color: colorController.textColor.value,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            formattedDate,
            style: TextStyle(
                color: colorController.textColor.value.withValues(alpha: 0.6)),
          ),
          trailing: isSelectionMode
              ? Checkbox(
                  value: isSelected,
                  activeColor: colorController.primaryColor.value,
                  side: BorderSide(
                      color: colorController.textColor.value.withValues(alpha: 0.5)),
                  onChanged: onSelectionChanged,
                )
              : null,
          onTap: onTap,
          onLongPress: onLongPress,
        ),
      ),
    )
        .animate()
        .fadeIn(
            duration: const Duration(milliseconds: 300),
            delay: Duration(milliseconds: 50 * index))
        .slideY(
            begin: 0.1,
            end: 0,
            duration: const Duration(milliseconds: 300),
            delay: Duration(milliseconds: 50 * index),
            curve: Curves.easeOut);
  }
}