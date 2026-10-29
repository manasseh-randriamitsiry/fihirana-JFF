import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';
import 'package:fihirana/shared/widgets/common/app_card.dart';
import 'package:fihirana/core/design_system/app_scale.dart';

class SettingsCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final int animationDelay;

  const SettingsCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();

    return AppCard(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppScale.space12),
            decoration: BoxDecoration(
              color: (iconColor ?? colorController.primaryColor.value)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor ?? colorController.primaryColor.value,
              size: 24,
            ),
          ),
          const SizedBox(width: AppScale.space16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colorController.textColor.value,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorController.textColor.value.withValues(alpha: 0.3),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: animationDelay),
            duration: const Duration(milliseconds: 300))
        .slideX(begin: -0.1, end: 0);
  }
}
