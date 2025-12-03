import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:fihirana/app/theme/color_controller.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final int? animationDelay;

  const SettingsSectionHeader({
    super.key,
    required this.title,
    this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    final colorController = Get.find<ColorController>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colorController.textColor.value.withValues(alpha: 0.6),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: animationDelay ?? 0),
      duration: const Duration(milliseconds: 400),
    );
  }
}