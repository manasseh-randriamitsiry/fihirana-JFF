import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/language_controller.dart';
import '../../../controller/splash_controller.dart';
import '../../../l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../widgets/intro/splash_widgets.dart';
import '../../../widgets/intro/page_indicator_widget.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final splashController = SplashController.to;
    final languageController = Get.find<LanguageController>();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B35),
            Color(0xFFF7931E),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated Background Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                    duration: const Duration(seconds: 4),
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                    curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(
                    duration: const Duration(seconds: 5),
                    begin: const Offset(1, 1),
                    end: const Offset(1.5, 1.5),
                    curve: Curves.easeInOut),
          ),

          // Content
          SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const SizedBox(height: 40),
                          Icon(
                            Icons.language,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.9),
                          )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .scale(delay: 200.ms, duration: 400.ms),
                          const SizedBox(height: 20),
                          Text(
                            l10n.chooseLanguage,
                            style: const TextStyle(
                              fontSize: 28.0,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(duration: 600.ms).slideY(
                              begin: 0.3,
                              end: 0,
                              duration: 600.ms,
                              curve: Curves.easeOut),
                          const SizedBox(height: 40),
                          _buildLanguageOptions(l10n, languageController, splashController)
                              .animate()
                              .fadeIn(delay: 300.ms, duration: 600.ms)
                              .slideY(
                                  begin: 0.2,
                                  end: 0,
                                  duration: 600.ms,
                                  curve: Curves.easeOut),
                        ],
                      ),
                    ),
                  ),
                ),
                Obx(() => PageIndicatorWidget(currentPage: splashController.currentPage.value, totalPages: 3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOptions(AppLocalizations l10n, LanguageController languageController, SplashController splashController) {
    return SplashCardWidget(
      color: Colors.white.withValues(alpha: 0.95),
      child: Column(
        children: [
          for (final locale in languageController.supportedLocales)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => splashController.selectLanguage(locale),
                borderRadius: BorderRadius.circular(20),
                child: Obx(() => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: splashController.selectedLocale.value?.languageCode == locale.languageCode
                        ? Colors.orange.shade100
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: splashController.selectedLocale.value?.languageCode == locale.languageCode
                          ? Colors.orange.shade300
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        languageController.getLanguageFlag(locale),
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          languageController.getLanguageName(locale),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: splashController.selectedLocale.value?.languageCode ==
                                    locale.languageCode
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: splashController.selectedLocale.value?.languageCode ==
                                    locale.languageCode
                                ? Colors.orange.shade800
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (splashController.selectedLocale.value?.languageCode == locale.languageCode)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                )),
              ),
            ),
        ],
      ),
    );
  }
}