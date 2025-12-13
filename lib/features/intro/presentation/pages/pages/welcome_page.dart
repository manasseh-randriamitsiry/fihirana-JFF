import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/intro/presentation/controllers/splash_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/features/intro/presentation/widgets/page_indicator_widget.dart';
import 'package:fihirana/features/intro/presentation/widgets/permission_request_dialog.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final splashController = SplashController.to;

    // Soft Pastel Teal/Aqua Palette
    const backgroundColor = Color(0xFFE0F7FA); // Very light cyan
    const primaryColor = Color(0xFF00ACC1); // Cyan
    const textColor = Color(0xFF006064); // Dark Cyan

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const Spacer(flex: 2),

                // Hero Illustration
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .scale(duration: 3000.ms, begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                     
                     Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.2),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        size: 100,
                        color: primaryColor,
                      ),
                    ).animate().scale(duration: 800.ms, curve: Curves.elasticOut).fadeIn(duration: 600.ms),
                  ],
                ),

                const Spacer(flex: 1),

                // Title Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        "Jesosy Famonjena Fahamarinantsika",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 16),

                      Text(
                        l10n.splashScreenSubtitle,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          color: textColor.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => PermissionRequestDialog(
                                onPermissionsGranted: () {
                                  Navigator.pop(context); // Close dialog
                                  splashController.liquidController.animateToPage(page: 2, duration: 600);
                                },
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 8,
                            shadowColor: primaryColor.withValues(alpha: 0.5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.getStarted,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.5, end: 0),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
             Positioned(
               bottom: 10,
               left: 0,
               right: 0,
               child: Obx(() => PageIndicatorWidget(currentPage: splashController.currentPage.value, totalPages: 3)),
             ), 
          ],
        ),
      ),
    );
  }
}