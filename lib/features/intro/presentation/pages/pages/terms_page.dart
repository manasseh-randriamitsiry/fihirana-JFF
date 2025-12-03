import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/intro/presentation/controllers/splash_controller.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/features/intro/presentation/widgets/splash_widgets.dart';
import 'package:fihirana/features/intro/presentation/widgets/page_indicator_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

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
            Color(0xFF4CAF50),
            Color(0xFF66BB6A),
            Color(0xFF43A047),
            Color(0xFF2E7D32),
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
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
                      duration: const Duration(seconds: 5),
                      begin: const Offset(1, 1),
                      end: const Offset(1.4, 1.4),
                      curve: Curves.easeInOut),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 200,
                height: 200,
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
                      duration: const Duration(seconds: 6),
                      begin: const Offset(1, 1),
                      end: const Offset(1.6, 1.6),
                      curve: Curves.easeInOut),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // Title
                      Text(
                        l10n.termsAndConditions,
                        style: const TextStyle(
                          fontSize: 24,
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
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: -0.2, end: 0, curve: Curves.easeOut),
                      const SizedBox(height: 24),

                      // Terms Card
                      Flexible(
                          child: SingleChildScrollView(
                            child: SplashCardWidget(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Header with expand/collapse button
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          l10n.agreement,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Obx(() => Icon(
                                          splashController.termsExpanded.value
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: Colors.green,
                                        )),
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          splashController.toggleTermsExpanded();
                                        },
                                        tooltip: splashController.termsExpanded.value
                                            ? 'Collapse'
                                            : 'Expand to read full terms',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Collapsible terms content
                                  Obx(() => AnimatedCrossFade(
                                    firstChild: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tap to expand and read full terms...',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                    secondChild: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AgreementItemWidget(text: l10n.term1),
                                        const SizedBox(height: 8),
                                        AgreementItemWidget(text: l10n.term2),
                                      ],
                                    ),
                                    crossFadeState: splashController.termsExpanded.value
                                        ? CrossFadeState.showSecond
                                        : CrossFadeState.showFirst,
                                    duration: const Duration(milliseconds: 300),
                                  )),
                                  const SizedBox(height: 16),

                                  // Agreement Checkbox
                                  InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      splashController.toggleAgreement();
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Obx(() => AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: splashController.agreementAccepted.value
                                            ? Colors.green.shade50
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: splashController.agreementAccepted.value
                                              ? Colors.green
                                              : Colors.grey.shade300,
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: splashController.agreementAccepted.value
                                                  ? Colors.green
                                                  : Colors.white,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: splashController.agreementAccepted.value
                                                    ? Colors.green
                                                    : Colors.grey,
                                                width: 2,
                                              ),
                                            ),
                                            child: splashController.agreementAccepted.value
                                                ? const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 16,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              l10n.acceptTerms,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
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
                           )).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale(
                              delay: 200.ms,
                              duration: 400.ms,
                              curve: Curves.easeOut),

                      const SizedBox(height: 20),

                      // Username Input and other form elements
                      Obx(() => _buildFormElements(l10n, splashController)),

                      const SizedBox(height: 60), // Space for page indicator
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

  Widget _buildFormElements(AppLocalizations l10n, SplashController splashController) {
    return Column(
      children: [
        // Username Input (only shown when agreement is accepted and not signed in with Google)
        if (splashController.agreementAccepted.value && !splashController.isGoogleUserSignedIn) ...[
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: TextField(
              controller: splashController.usernameController,
              maxLength: 15,
              style: const TextStyle(fontSize: 15, color: Colors.black),
              decoration: InputDecoration(
                labelText: l10n.enterYourName,
                labelStyle: const TextStyle(color: Colors.green, fontSize: 14),
                prefixIcon: const Icon(Icons.person_outline, color: Colors.green, size: 22),
                border: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                fontSize: 12,
                color: splashController.usernameLength.value >= 4
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
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
            child: Obx(() => ElevatedButton.icon(
              onPressed: !splashController.isSigningIn.value ? splashController.handleGoogleSignIn : null,
              icon: splashController.isSigningIn.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Image.asset(
                      'assets/images/google_logo.png',
                      height: 24,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.login, size: 24),
                    ),
              label: Text(
                splashController.isSigningIn.value ? l10n.signingIn : l10n.signInWithGoogle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
            )),
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 600.ms)
              .scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.3),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.orDivider,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.3),
                  thickness: 1,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
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
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
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
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Obx(() => Text(
                          splashController.googleUserName.value,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        )),
                        Obx(() => Text(
                          splashController.googleUserEmail.value,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
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

          if (splashController.isGoogleUserSignedIn || splashController.usernameController.text.trim().length >= 4)
            SizedBox(
              width: double.infinity,
              child: Obx(() => ElevatedButton.icon(
                onPressed: !splashController.isSigningIn.value
                    ? splashController.isGoogleUserSignedIn
                        ? splashController.handleGoogleUserContinue
                        : splashController.usernameController.text.trim().length >= 4
                            ? splashController.handleUsernameSubmit
                            : null
                    : null,
                icon: splashController.isGoogleUserSignedIn
                    ? const Icon(Icons.check_circle, size: 20)
                    : const Icon(Icons.person_outline, size: 20),
                label: Text(
                  splashController.getContinueButtonText(l10n.continueAs(splashController.googleUserName.value), l10n.continueAsGuest),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: splashController.usernameController.text.trim().length >= 4 ||
                          splashController.isGoogleUserSignedIn
                      ? Colors.white
                      : Colors.grey.shade300,
                  foregroundColor: splashController.usernameController.text.trim().length >= 4 ||
                          splashController.isGoogleUserSignedIn
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: splashController.usernameController.text.trim().length >= 4 ||
                          splashController.isGoogleUserSignedIn
                      ? 8
                      : 0,
                ),
              )),
            )
                .animate()
                .fadeIn(
                    delay: splashController.isGoogleUserSignedIn ? 400.ms : 600.ms,
                    duration: 600.ms)
                .scale(
                    delay: splashController.isGoogleUserSignedIn ? 400.ms : 600.ms,
                    duration: 400.ms,
                    curve: Curves.easeOutBack),
        ],
      ],
    );
  }
}