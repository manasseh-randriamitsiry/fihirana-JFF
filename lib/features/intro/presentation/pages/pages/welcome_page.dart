import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/features/intro/presentation/controllers/splash_controller.dart';
import 'package:fihirana/features/intro/presentation/widgets/page_indicator_widget.dart';
import 'package:fihirana/features/intro/presentation/widgets/permission_request_dialog.dart';
import 'package:fihirana/l10n/app_localizations.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final splashController = SplashController.to;
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 112,
                  height: 112,
                  child: Icon(Icons.music_note_rounded, size: 54),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Jesosy Famonjena Fahamarinantsika',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                l10n.splashScreenSubtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.45),
              ),
            ),
            const Spacer(flex: 2),
            FilledButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => PermissionRequestDialog(
                  onPermissionsGranted: () {
                    Navigator.of(context).pop();
                    splashController.goToPage(2);
                  },
                ),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(l10n.getStarted),
            ),
            const SizedBox(height: 16),
            Obx(
              () => PageIndicatorWidget(
                currentPage: splashController.currentPage.value,
                totalPages: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
