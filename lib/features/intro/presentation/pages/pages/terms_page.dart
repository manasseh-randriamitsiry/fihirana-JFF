import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/intro/presentation/controllers/splash_controller.dart';
import 'package:fihirana/features/intro/presentation/controllers/username_input_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/features/intro/presentation/widgets/splash_widgets.dart';
import 'package:fihirana/features/intro/presentation/widgets/page_indicator_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fihirana/core/constants/app_dimensions.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

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
            Color(0xFFFFF3E0), // Light orange
            Color(0xFFFCE4EC), // Light pink
            Color(0xFFF3E5F5), // Light purple
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: 20.0),
              child: Column(
                children: [
                  const Spacer(flex: 2),
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
                      Icons.description_rounded,
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

                  const SizedBox(height: 12),

                  // Title
                  Text(
                    l10n.termsAndConditions,
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

                  const Spacer(),

                   // Terms Card
                   IntrinsicHeight(
                     child: Container(
                        padding: const EdgeInsets.all(12),
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
                           crossAxisAlignment: CrossAxisAlignment.start,
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             // Header (hidden when accepted)
                             Obx(() => splashController.agreementAccepted.value
                                 ? const SizedBox.shrink()
                                 : Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       Expanded(
                                         child: Text(
                                           l10n.agreement,
                                           style: TextStyle(
                                             fontSize: 18,
                                             fontWeight: FontWeight.bold,
                                             color: colorScheme.onSurface,
                                           ),
                                         ),
                                       ),
                                       IconButton(
                                         icon: Obx(() => Icon(
                                           splashController.termsExpanded.value
                                               ? Icons.expand_less
                                               : Icons.expand_more,
                                           color: colorScheme.primary,
                                         )),
                                         onPressed: () {
                                           HapticFeedback.selectionClick();
                                           splashController.toggleTermsExpanded();
                                         },
                                         tooltip: splashController.termsExpanded.value
                                             ? 'Collapse terms'
                                             : 'Expand to read full terms',
                                       ),
                                     ],
                                   )),
                             // Spacing (only when header is shown)
                             Obx(() => splashController.agreementAccepted.value
                                 ? const SizedBox.shrink()
                                 : const SizedBox(height: 12)),

                             // Terms content (hidden when accepted)
                             Obx(() => splashController.agreementAccepted.value
                                 ? const SizedBox.shrink()
                                 : Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       AgreementItemWidget(text: l10n.term1),
                                       const SizedBox(height: 8),
                                       AgreementItemWidget(text: l10n.term2),
                                     ],
                                   ).animate().fadeIn(duration: 300.ms)),
                            const SizedBox(height: 16),

                            // Agreement Checkbox
                            InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                splashController.toggleAgreement();
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Obx(() => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: splashController.agreementAccepted.value
                                      ? colorScheme.primaryContainer
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: splashController.agreementAccepted.value
                                        ? colorScheme.primary
                                        : colorScheme.outline,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: splashController.agreementAccepted.value
                                            ? colorScheme.primary
                                            : colorScheme.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: splashController.agreementAccepted.value
                                              ? colorScheme.primary
                                              : colorScheme.outline,
                                          width: 2,
                                        ),
                                      ),
                                      child: splashController.agreementAccepted.value
                                          ? Icon(
                                              Icons.check,
                                              color: colorScheme.onPrimary,
                                              size: 16,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        l10n.acceptTerms,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ),
                           ],
                         ),
                     ),
                   ).animate().fadeIn(delay: 600.ms, duration: 600.ms).scale(
                      delay: 600.ms,
                      duration: 400.ms,
                      curve: Curves.easeOut),

                  const SizedBox(height: 12),

                  // Username Input and other form elements
                  Obx(() => _buildFormElements(l10n, splashController, colorScheme)),

                  const Spacer(flex: 2),
                ],
              ),
              ),
            Obx(() => PageIndicatorWidget(
                  currentPage: splashController.currentPage.value,
                  totalPages: 3,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildFormElements(AppLocalizations l10n, SplashController splashController, ColorScheme colorScheme) {
    return Column(
      children: [
        // Username Input (only shown when agreement is accepted and not signed in with Google)
        if (splashController.agreementAccepted.value && !splashController.isGoogleUserSignedIn) ...[
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: splashController.usernameController,
              maxLength: 15,
              style: TextStyle(fontSize: 16, color: colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: l10n.enterYourName,
                labelStyle: TextStyle(color: colorScheme.primary, fontSize: 14),
                prefixIcon: Icon(Icons.person_outline, color: colorScheme.primary, size: 24),
                border: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 600.ms)
              .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

          // Helper text for character count
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Obx(() => Text(
              '${splashController.usernameLength.value}/15 characters (minimum 4)',
              style: TextStyle(
                fontSize: 14,
                color: splashController.usernameLength.value >= 4
                    ? colorScheme.primary
                    : colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            )),
          ),
        ],

        // Google Sign In Button
        if (splashController.agreementAccepted.value && !splashController.isGoogleUserSignedIn) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Obx(() => OutlinedButton.icon(
              onPressed: !splashController.isSigningIn.value ? splashController.handleGoogleSignIn : null,
              icon: splashController.isSigningIn.value
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      ),
                    )
                  : Image.asset(
                      'assets/images/google_logo.png',
                      height: 24,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.login, size: 24, color: colorScheme.primary),
                    ),
              label: Text(
                splashController.isSigningIn.value ? l10n.signingIn : l10n.signInWithGoogle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                backgroundColor: colorScheme.surface,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            )),
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 600.ms)
              .scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
        ],

        // Continue Button
        if (splashController.agreementAccepted.value) ...[
          // User Info Display (when Google user is signed in)
          if (splashController.isGoogleUserSignedIn)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.signedInAsLabel,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(() => Text(
                          splashController.googleUserName.value,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        )),
                        Obx(() => Text(
                          splashController.googleUserEmail.value,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
               ),
             )
             .animate()
             .fadeIn(delay: 200.ms, duration: 600.ms)
             .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

          Obx(() {
            final usernameController = Get.find<UsernameInputController>();
            return splashController.isGoogleUserSignedIn || usernameController.usernameLength.value >= 4
                ? SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: splashController.isGoogleUserSignedIn
                          ? splashController.handleGoogleUserContinue
                          : Get.find<UsernameInputController>().usernameLength.value >= 4
                              ? splashController.handleUsernameSubmit
                              : null,
                      icon: splashController.isGoogleUserSignedIn
                          ? Icon(Icons.check_circle, size: 20, color: colorScheme.onPrimary)
                          : Icon(Icons.person_outline, size: 20, color: colorScheme.onPrimary),
                      label: Text(
                        splashController.getContinueButtonText(l10n.continueAs('{name}'), l10n.continueAsGuest),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(
                      delay: splashController.isGoogleUserSignedIn ? 400.ms : 600.ms,
                      duration: 600.ms)
                  .scale(
                      delay: splashController.isGoogleUserSignedIn ? 400.ms : 600.ms,
                      duration: 400.ms,
                      curve: Curves.easeOutBack)
                : const SizedBox.shrink();
          }),
        ],
      ],
    );
  }
}