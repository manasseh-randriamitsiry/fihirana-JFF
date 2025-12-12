import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/intro/presentation/controllers/splash_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/features/intro/presentation/widgets/page_indicator_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';
import 'package:fihirana/core/constants/app_colors.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final splashController = SplashController.to;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(
          color: AppColors.successLight
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
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.1),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 75,
                      color: colorScheme.primary,
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
                  const Text(
                    "Jesosy Famonjena Fahamarinantsika",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    l10n.splashScreenSubtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
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
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.getStarted,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.xxl),
                          const Icon(Icons.arrow_forward),
                        ],
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