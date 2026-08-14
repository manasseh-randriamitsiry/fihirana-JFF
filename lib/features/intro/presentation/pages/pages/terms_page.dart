import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fihirana/features/intro/presentation/controllers/splash_controller.dart';
import 'package:fihirana/features/intro/presentation/controllers/username_input_controller.dart';
import 'package:fihirana/features/intro/presentation/widgets/splash_widgets.dart';
import 'package:fihirana/features/intro/presentation/widgets/username_input_widget.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/shared/widgets/common/app_ui.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final splashController = SplashController.to;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                    child: Icon(Icons.verified_user_outlined, size: 42)),
                const SizedBox(height: 20),
                Center(
                  child: Text(l10n.termsAndConditions,
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    l10n.reviewOnboardingEssentials,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 24),
                AppGroupedSurface(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.agreement,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 14),
                          AgreementItemWidget(text: l10n.term1),
                          const SizedBox(height: 12),
                          AgreementItemWidget(text: l10n.term2),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Obx(
                  () => CheckboxListTile(
                    value: splashController.agreementAccepted.value,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(l10n.acceptTerms),
                    onChanged: (_) => splashController.toggleAgreement(),
                  ),
                ),
                const SizedBox(height: 16),
                _AccountActions(
                  l10n: l10n,
                  splashController: splashController,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountActions extends StatelessWidget {
  final AppLocalizations l10n;
  final SplashController splashController;

  const _AccountActions({required this.l10n, required this.splashController});

  @override
  Widget build(BuildContext context) {
    final usernameController = Get.find<UsernameInputController>();
    return Obx(() {
      final agreementAccepted = splashController.agreementAccepted.value;
      final hasUsername = usernameController.usernameLength.value >= 4;
      final signedIn = splashController.isGoogleUserSignedIn;
      final isSigningIn = splashController.isSigningIn.value;

      if (!agreementAccepted) {
        return FilledButton(
          onPressed: null,
          child: Text(l10n.acceptTermsToContinue),
        );
      }

      return Column(
        children: [
          if (!signedIn) ...[
            UsernameInputWidget(
              controller: splashController.usernameController,
              labelText: l10n.enterYourName,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed:
                  isSigningIn ? null : splashController.handleGoogleSignIn,
              icon: isSigningIn
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(isSigningIn ? l10n.signingIn : l10n.signInWithGoogle),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            onPressed: signedIn || hasUsername
                ? (signedIn
                    ? splashController.handleGoogleUserContinue
                    : splashController.handleUsernameSubmit)
                : null,
            child: Text(
              signedIn
                  ? l10n.continueAs(splashController.googleUserName.value)
                  : hasUsername
                      ? l10n.continueAs(
                          splashController.usernameController.text.trim())
                      : l10n.enterAtLeastCharacters,
            ),
          ),
        ],
      );
    });
  }
}
