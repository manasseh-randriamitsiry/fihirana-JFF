import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/core/localization/language_controller.dart';
import 'package:fihirana/features/intro/presentation/controllers/splash_controller.dart';
import 'package:fihirana/features/intro/presentation/widgets/page_indicator_widget.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';
import 'package:fihirana/core/design_system/app_scale.dart';

class LanguageSelectionPage extends StatelessWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final splashController = SplashController.to;
    final languageController = Get.find<LanguageController>();

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppScale.space24, AppScale.space24,
              AppScale.space24, AppScale.space16),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppScale.space24),
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: .12),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 88,
                      height: 88,
                      child: Icon(Icons.language_rounded, size: 42),
                    ),
                  ),
                ),
                const SizedBox(height: AppScale.space24),
                Center(
                  child: Text(l10n.chooseLanguage,
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
                const SizedBox(height: AppScale.space8),
                Center(
                  child: Text(
                    l10n.languageSelectionDescription,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: AppScale.space24),
                Obx(
                  () => AppGroupedSurface(
                    children: List.generate(
                        languageController.supportedLocales.length, (index) {
                      final locale = languageController.supportedLocales[index];
                      final selected =
                          splashController.selectedLocale.value?.languageCode ==
                              locale.languageCode;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () =>
                                splashController.selectLanguage(locale),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppScale.space16,
                                  vertical: AppScale.space16),
                              child: Row(
                                children: [
                                  Text(
                                      languageController
                                          .getLanguageFlag(locale),
                                      style: const TextStyle(fontSize: 24)),
                                  const SizedBox(width: AppScale.space16),
                                  Expanded(
                                    child: Text(
                                      languageController
                                          .getLanguageName(locale),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: selected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                    ),
                                  ),
                                  if (selected)
                                    Icon(Icons.check_circle_rounded,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary),
                                ],
                              ),
                            ),
                          ),
                          if (index <
                              languageController.supportedLocales.length - 1)
                            const AppGroupDivider(),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: AppScale.gutter),
                Obx(
                  () => FilledButton(
                    onPressed: splashController.selectedLocale.value == null
                        ? null
                        : () => splashController.goToPage(1),
                    child: Text(l10n.continueText),
                  ),
                ),
                const SizedBox(height: AppScale.space16),
                Obx(
                  () => PageIndicatorWidget(
                    currentPage: splashController.currentPage.value,
                    totalPages: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
