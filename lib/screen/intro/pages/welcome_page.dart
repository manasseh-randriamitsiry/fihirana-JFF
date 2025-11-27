import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../controller/splash_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/intro/splash_widgets.dart';
import '../../../widgets/intro/page_indicator_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final splashController = SplashController.to;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Animated Background Elements
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(
                      duration: const Duration(seconds: 4),
                      begin: const Offset(1, 1),
                      end: const Offset(1.3, 1.3),
                      curve: Curves.easeInOut),
            ),
            Positioned(
              bottom: 100,
              left: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(
                      duration: const Duration(seconds: 5),
                      begin: const Offset(1, 1),
                      end: const Offset(1.5, 1.5),
                      curve: Curves.easeInOut),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // App Icon with glow effect
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withValues(alpha: 0.3),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: Colors.pink.withValues(alpha: 0.2),
                              blurRadius: 60,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          size: 64,
                          color: Color(0xFF6366F1),
                        ),
                      )
                          .animate()
                          .scale(
                              duration: 800.ms,
                              curve: Curves.elasticOut,
                              begin: const Offset(0, 0),
                              end: const Offset(1, 1))
                          .then(delay: 200.ms)
                          .shimmer(
                              duration: 2000.ms,
                              color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        l10n.splashScreenTitle,
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 8,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        l10n.splashScreenSubtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                      const SizedBox(height: 40),

                      // Feature Cards
                      SplashCardWidget(
                        padding: const EdgeInsets.all(20),
                        color: Colors.white.withValues(alpha: 0.95),
                        child: Column(
                          children: [
                            FeatureItemWidget(icon: Icons.library_music, text: l10n.appFeature1),
                            const SizedBox(height: 12),
                            FeatureItemWidget(icon: Icons.mic_rounded, text: l10n.appFeature2),
                            const SizedBox(height: 12),
                            FeatureItemWidget(icon: Icons.sync_rounded, text: l10n.appFeature3),
                            const SizedBox(height: 12),
                            FeatureItemWidget(icon: Icons.people_rounded, text: l10n.appFeature4),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                      const SizedBox(height: 32),

                      // Get Started Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            splashController.liquidController.animateToPage(page: 2, duration: 600);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: Colors.black.withValues(alpha: 0.3),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.getStarted,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 24),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms, duration: 600.ms).scale(
                          delay: 600.ms,
                          duration: 400.ms,
                          curve: Curves.easeOutBack),
                    ],
                  ),
                ),
              ),
            ),
            Obx(() => PageIndicatorWidget(currentPage: splashController.currentPage.value, totalPages: 3)),
          ],
        ),
      ),
    );
  }
}