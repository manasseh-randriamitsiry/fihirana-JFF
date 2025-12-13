import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/intro/presentation/controllers/splash_controller.dart';
import 'package:fihirana/features/intro/presentation/controllers/username_input_controller.dart';
import 'package:fihirana/features/intro/presentation/widgets/username_input_widget.dart';
import 'package:fihirana/l10n/app_localizations.dart';
import 'package:fihirana/features/intro/presentation/widgets/splash_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final splashController = SplashController.to;
    
    // Soft Pastel Orange/Cream Palette
    const backgroundColor = Color(0xFFFFF8E1); // Very light amber/cream
    const primaryColor = Color(0xFFFF8F00); // Amber
    const textColor = Color(0xFF3E2723); // Dark Brown

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  children: [
                   // Icon
                    Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.policy_rounded,
                          size: 30,
                          color: primaryColor,
                        ),
                      )
                      .animate()
                      .scale(duration: 800.ms, curve: Curves.elasticOut)
                      .fadeIn(duration: 600.ms),
                    ),

                    const SizedBox(height: 12),

                    // Title
                    Text(
                      l10n.termsAndConditions,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 4),

                    Text(
                      "Please review and accept our terms to continue",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 12),

                    // Terms Card (Scrollable area inside)
                    // Using Flexible to allow minimizing if content is short, but taking space if needed.
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 150), // Ensure at least some visibility
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.agreement,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AgreementItemWidget(text: l10n.term1,),
                                const SizedBox(height: 16),
                                AgreementItemWidget(text: l10n.term2),
                                const SizedBox(height: 16),
                                // Extra dummy text to ensure scrolling is testable
                                Text(
                                  "By using this application, you agree to our Terms of Service and Privacy Policy. We respect your data and privacy.",
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                    ),

                    const SizedBox(height: 16),

                    // Checkbox and Accept
                    Column(
                      children: [
                         InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              splashController.toggleAgreement();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Obx(() => Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: splashController.agreementAccepted.value
                                        ? primaryColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: splashController.agreementAccepted.value
                                          ? primaryColor
                                          : textColor.withValues(alpha: 0.4),
                                      width: 2,
                                    ),
                                  ),
                                  child: splashController.agreementAccepted.value
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    l10n.acceptTerms,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            )),
                          ),
                          const SizedBox(height: 24),

                          // Logic for Username / Google Sign In or Continue
                          Obx(() => _buildActionButtons(context, l10n, splashController, primaryColor, textColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n, SplashController splashController, Color primaryColor, Color textColor) {
    // If not accepted yet, show disabled button or nothing?
    // The design usually shows a button that becomes active.
    
    if (!splashController.agreementAccepted.value) {
       return SizedBox(
         width: double.infinity,
         child: FilledButton(
            onPressed: null, // Disabled
            style: FilledButton.styleFrom(
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(vertical: 18),
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(28),
               ),
            ),
            child: Text(l10n.acceptTerms, style: TextStyle(color: textColor.withValues(alpha: 0.4))),
         ),
       );
    }

    // Accepted state: Show Google Sign In or Username Input
    return Column(
      children: [
        if (!splashController.isGoogleUserSignedIn) ...[
          // Username Input
          UsernameInputWidget(
            controller: splashController.usernameController,
            labelText: l10n.enterYourName,
            accentColor: primaryColor,
          ).animate().fadeIn(),
          
          const SizedBox(height: 16),
          
          // Google Sign In
          OutlinedButton.icon(
             onPressed: !splashController.isSigningIn.value ? splashController.handleGoogleSignIn : null,
             icon: splashController.isSigningIn.value 
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))
                : Image.asset('assets/images/google_logo.png', height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.login)),
             label: Text(splashController.isSigningIn.value ? l10n.signingIn : l10n.signInWithGoogle),
             style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                foregroundColor: textColor,
             ),
          ).animate().fadeIn(),
        ],

        const SizedBox(height: 16),

        // Continue Button
        // Show if Google Signed In OR Username is valid
        if (splashController.isGoogleUserSignedIn || Get.find<UsernameInputController>().usernameLength.value >= 4)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                 if (splashController.isGoogleUserSignedIn) {
                   splashController.handleGoogleUserContinue();
                 } else if (Get.find<UsernameInputController>().usernameLength.value >= 4) {
                   splashController.handleUsernameSubmit();
                 }
              },
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                 padding: const EdgeInsets.symmetric(vertical: 18),
                 shape: RoundedRectangleBorder(
                   borderRadius: BorderRadius.circular(28),
                 ),
                 elevation: 4,
                 shadowColor: primaryColor.withValues(alpha: 0.4),
              ),
              child: Text(
                 splashController.isGoogleUserSignedIn 
                    ? l10n.continueAs(splashController.googleUserName.value)
                    : l10n.continueAs(splashController.usernameController.text),
                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
      ],
    );
  }
}