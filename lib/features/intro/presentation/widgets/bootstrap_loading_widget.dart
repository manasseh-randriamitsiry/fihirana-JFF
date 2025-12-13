import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class BootstrapLoadingWidget extends StatelessWidget {
  final double progress;
  final bool isTablet;

  const BootstrapLoadingWidget({
    super.key,
    required this.progress,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isTablet ? 400 : double.infinity,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading Animation
            LoadingAnimationWidget.staggeredDotsWave(
              color: colorScheme.primary,
              size: isTablet ? 60 : 100,
            ),

            SizedBox(height: isTablet ? 30 : 40),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 8,
                width: double.infinity,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
            ),

            SizedBox(height: isTablet ? 15 : 20),

            // Percentage text
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: isTablet ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),

            const SizedBox(height: 10),

            // Current task text
            Text(
              'Initializing...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 14 : 16,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}