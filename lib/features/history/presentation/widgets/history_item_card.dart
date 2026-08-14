import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';
import 'package:fihirana/shared/widgets/common/app_card.dart';

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
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = colors.surface;
    final primaryColor = colors.primary;
    final textColor = colors.onSurface;

    // Pastel color like hymn list item
    final pastelColor = Color.alphaBlend(
      primaryColor.withValues(alpha: 0.05),
      backgroundColor,
    );

    final DateTime timestamp = DateTime.parse(history['timestamp']);
    final String formattedDate =
        '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onLongPress: onLongPress,
        child: AppCard(
          backgroundColor: pastelColor,
          borderRadius: AppDimensions.radiusXxl,
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Hymn Number Badge
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${history['number']}',
                  style: textTheme.titleMedium?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Title and Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history['title'] ?? 'Hira ${history['number']}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: textTheme.bodyMedium?.copyWith(
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Selection checkbox
              if (isSelectionMode)
                Checkbox(
                  value: isSelected,
                  activeColor: primaryColor,
                  side: BorderSide(
                    color: textColor.withValues(alpha: 0.5),
                  ),
                  onChanged: onSelectionChanged,
                ),
            ],
          ),
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
