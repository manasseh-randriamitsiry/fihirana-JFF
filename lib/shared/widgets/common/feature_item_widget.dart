import 'package:flutter/material.dart';
import 'package:fihirana/core/design_system/app_scale.dart';

class FeatureItemWidget extends StatelessWidget {
  final IconData icon;
  final String text;

  const FeatureItemWidget({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppScale.space12),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppScale.radiusRow),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6366F1),
            size: 24,
          ),
        ),
        const SizedBox(width: AppScale.space16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
