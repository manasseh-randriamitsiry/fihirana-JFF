import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import 'package:fihirana/app/theme/color_controller.dart';

class AboutSectionTitleWidget extends StatelessWidget {
  final String title;

  const AboutSectionTitleWidget({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colorController.textColor.value.withValues(alpha: 0.6),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class AboutActionCardWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final int animationDelay;

  const AboutActionCardWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorController.textColor.value.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      color: backgroundColor ?? colorController.backgroundColor.value,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
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
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: iconColor ?? colorController.textColor.value,
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
        ),
      ),
    )
        .animate()
        .fadeIn(
            delay: Duration(milliseconds: animationDelay),
            duration: const Duration(milliseconds: 300))
        .slideX(begin: -0.1, end: 0);
  }
}

class AboutStatCardWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const AboutStatCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: iconColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colorController.textColor.value,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorController.textColor.value
                          .withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 300))
        .slideY(begin: -0.1, end: 0);
  }
}