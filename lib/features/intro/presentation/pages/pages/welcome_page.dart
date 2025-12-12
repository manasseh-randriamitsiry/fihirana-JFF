import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/intro/presentation/controllers/splash_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/features/intro/presentation/widgets/page_indicator_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final splashController = SplashController.to;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE8F2FF), // Very light blue
            Color(0xFFF3E5F5), // Very light lavender
            Color(0xFFFFF3E0), // Very light peach
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Large friendly illustration
                  Container(
                    width: 280,
                    height: 280,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x1F000000), // Colors.black.withValues(alpha: 0.12)
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      size: 120,
                      color: Color(0xFF9C27B0),
                    ),
                  )
                      .animate()
                      .scale(
                          duration: 1000.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1, 1))
                      .fadeIn(duration: 800.ms),

                  const Spacer(),

                  // Title
                  Text(
                    l10n.splashScreenTitle,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    l10n.splashScreenSubtitle,
                    style: TextStyle(
                      fontSize: 18,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                  const Spacer(flex: 2),

                  // Primary button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        splashController.liquidController.animateToPage(page: 2, duration: 600);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        l10n.getStarted,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                  const SizedBox(height: 80), // Extra space for page indicator
                ],
              ),
            ),

            // Page indicator positioned at bottom
            Obx(() => PageIndicatorWidget(
                  currentPage: splashController.currentPage.value,
                  totalPages: 3,
                )),
          ],
        ),
      ),
    );
  }
}