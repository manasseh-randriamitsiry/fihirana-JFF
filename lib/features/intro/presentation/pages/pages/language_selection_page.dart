import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';
import 'package:fihirana/core/localization/language_controller.dart';
import 'package:fihirana/features/intro/presentation/controllers/splash_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fihirana/features/intro/presentation/widgets/page_indicator_widget.dart';
import 'package:fihirana/core/constants/app_colors.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final splashController = SplashController.to;
    final languageController = Get.find<LanguageController>();

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
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
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.1),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.language_rounded,
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
                  Text(
                    l10n.chooseLanguage,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 600.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'Select your preferred language to continue',
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                  const Spacer(),

                  // Language options
                  _buildLanguageOptions(l10n, languageController, splashController, colorScheme)
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                  const Spacer(flex: 2),
                ],
              ),
            ),
            Obx(() => PageIndicatorWidget(currentPage: splashController.currentPage.value, totalPages: 3)),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOptions(AppLocalizations l10n, LanguageController languageController, SplashController splashController, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          for (final locale in languageController.supportedLocales)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => splashController.selectLanguage(locale),
                borderRadius: BorderRadius.circular(16),
                child: Obx(() => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: splashController.selectedLocale.value?.languageCode == locale.languageCode
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: splashController.selectedLocale.value?.languageCode == locale.languageCode
                          ? colorScheme.primary
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
                                : FontWeight.w500,
                            color: splashController.selectedLocale.value?.languageCode ==
                                    locale.languageCode
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                        ),
                        if (splashController.selectedLocale.value?.languageCode == locale.languageCode)
                         Container(
                           padding: const EdgeInsets.all(6),
                           decoration: BoxDecoration(
                             color: colorScheme.primary,
                             shape: BoxShape.circle,
                           ),
                           child: Icon(
                             Icons.check,
                             color: colorScheme.onPrimary,
                             size: 16,
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