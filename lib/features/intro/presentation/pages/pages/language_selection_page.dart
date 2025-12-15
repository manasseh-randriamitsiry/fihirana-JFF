import 'package:fihirana/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';
import 'package:fihirana/core/localization/language_controller.dart';
import 'package:fihirana/features/intro/presentation/controllers/splash_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fihirana/features/intro/presentation/widgets/page_indicator_widget.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final splashController = SplashController.to;
    final languageController = Get.find<LanguageController>();

    // Soft Pastel Violet Palette
    const backgroundColor = AppColors.warningLight; // Very light purple
    const primaryColor = AppColors.primary; // Purple

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const Spacer(flex: 1),
                
                // Illustration Area
                Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.public_rounded,
                      size: 80,
                      color: primaryColor,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(duration: 2000.ms, begin: const Offset(1, 1), end: const Offset(1.05, 1.05))
                  .then()
                  .scale(duration: 2000.ms, begin: const Offset(1.05, 1.05), end: const Offset(1, 1)),
                )
                .animate()
                .slideY(begin: -0.2, end: 0, duration: 600.ms, curve: Curves.easeOutBack)
                .fadeIn(duration: 600.ms),

                const SizedBox(height: 40),

                // Title Section
                Text(
                  l10n.chooseLanguage,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A148C), // Dark Purple
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 12),

                Text(
                  'Select your preferred language to get started',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF7B1FA2).withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                const Spacer(flex: 1),

                // Language Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
                  child: Column(
                    children: [
                      for (final locale in languageController.supportedLocales)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Obx(() {
                            final isSelected = splashController.selectedLocale.value?.languageCode == locale.languageCode;
                            return Material(
                              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                              elevation: isSelected ? 4 : 0,
                              shadowColor: primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(24),
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  splashController.selectLanguage(locale);
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected ? primaryColor : Colors.transparent,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          languageController.getLanguageFlag(locale),
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Text(
                                          languageController.getLanguageName(locale),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? const Color(0xFF4A148C) : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                    ],
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                ),

                const Spacer(flex: 2),

                // Continue Button (Only visible logic is handled in PageView flow usually, but layout wise it sits here)
                // Actually in the original code, there was no continue button on this page, 
                // but the prompt asked for "Big rounded primary button Continue at bottom"
                // However, the original flow uses a PageView with `PageIndicatorWidget`.
                // I should assume the PageView controller swipes or there is a "Continue" to swipe.
                // Looking at `splash_screen_authenticated.dart` or wrapper might reveal how navigation works.
                // But the user prompt explicitly requested a button. 
                // "Big rounded primary button “Continue” at bottom"
                // I will add a button that swipes to the next page.
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.lg),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                         splashController.liquidController.animateToPage(page: 1, duration: 600);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 4,
                        shadowColor: primaryColor.withValues(alpha: 0.4),
                      ),
                      child: const Text(
                        "Continue",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.5, end: 0),

                const SizedBox(height: 40),
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
