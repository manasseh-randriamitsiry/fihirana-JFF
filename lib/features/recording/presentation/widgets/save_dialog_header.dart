import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fihirana/core/design_system/app_scale.dart';

class SaveDialogHeader extends StatelessWidget {
  const SaveDialogHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Success icon
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(AppScale.radiusFloat),
          ),
          child: const Icon(
            Icons.check_circle,
            size: 32,
            color: Colors.green,
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),

        const SizedBox(height: AppScale.gutter),

        const Text(
          'Enregistrement terminé !',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: AppScale.space24),
      ],
    );
  }
}
