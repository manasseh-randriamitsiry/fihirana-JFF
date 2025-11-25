import 'package:fihirana/screen/accueil/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import '../../l10n/app_localizations.dart';
import '../../controller/language_controller.dart';
import '../../controller/recording_controller.dart';
import '../../controller/auth_controller.dart';
import '../../services/google_drive_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';


class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({super.key});

  @override
  State<SplashScreen1> createState() => _SplashScreen1State();
}

class _SplashScreen1State extends State<SplashScreen1> {
  final TextEditingController _usernameController = TextEditingController();
  bool _agreementAccepted = false;
  int _currentPage = 0;
  bool _isSigningIn = false;
  String? _googleUserName;
  String? _googleUserEmail;

// Language selection state variables
  late final LanguageController languageController;
  Locale? selectedLocale;

  // Liquid swipe controller
  late LiquidController _liquidController;

  // Helper getter for Google sign-in status
  bool get isGoogleUserSignedIn =>
      _googleUserName != null && _googleUserEmail != null;

  @override
  void initState() {
    super.initState();
    _checkAgreementStatus();
    _checkGoogleSignInStatus();

    // Initialize language controller
    languageController = Get.find<LanguageController>();
    selectedLocale = languageController.currentLocaleValue;

    // Initialize liquid swipe controller
    _liquidController = LiquidController();

    // Add listener to username controller to update button text dynamically
    _usernameController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _checkGoogleSignInStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && mounted) {
        setState(() {
          _googleUserName = user.displayName ?? user.email?.split('@')[0];
          _googleUserEmail = user.email;
        });
      }
    } catch (e) {
      // User not signed in or error occurred
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Widget _buildCard({
    required Widget child,
    EdgeInsets? padding,
    Color? color,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _saveAndProceed() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenLanguageSelection', true);

    // Animate to next page
    await _liquidController.animateToPage(page: 1, duration: 600);
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isSigningIn) return;

    setState(() {
      _isSigningIn = true;
    });

    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context)!;

    try {
      // Sign in with Google (Firebase)
      final authController = Get.find<AuthController>();
      final userCredential = await authController.signInWithGoogle();

      if (userCredential == null) {
        if (mounted) {
          setState(() {
            _isSigningIn = false;
          });
        }
        return;
      }

      // Sign in to Google Drive
      final driveService = GoogleDriveService();
      await driveService.signIn();

      // Save preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_agreed_to_terms', true);
      await prefs.setBool('isFirstTime', false);

      // Navigate to home
      Get.offAll(() => const HomeScreen());
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          l10n.errorOccurred,
          l10n.googleSignInFailed,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Future<void> _handleUsernameSubmit() async {
    HapticFeedback.mediumImpact();

    final username = _usernameController.text.trim();
    final l10n = AppLocalizations.of(context)!;

    if (username.isEmpty) {
      Get.snackbar(
        l10n.errorOccurred,
        l10n.enterYourName,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    // Validate username length (4-15 characters)
    if (username.length < 4 || username.length > 15) {
      Get.snackbar(
        l10n.errorOccurred,
        'Name must be between 4 and 15 characters',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setBool('has_agreed_to_terms', true);
      await prefs.setBool('isFirstTime', false);

      // Also save to RecordingController for guest recordings
      final recordingController = Get.find<RecordingController>();
      await recordingController.setGuestName(username);

      Get.offAll(() => const HomeScreen());
    } catch (e) {
      Get.snackbar(
        l10n.errorOccurred,
        l10n.nameNotSaved,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleGoogleUserContinue() async {
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context)!;

    try {
      // Save preferences for Google user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _googleUserName!);
      await prefs.setString('email', _googleUserEmail!);
      await prefs.setBool('has_agreed_to_terms', true);
      await prefs.setBool('isFirstTime', false);
      await prefs.setBool('is_google_user', true);

      // Also save to RecordingController for user recordings
      final recordingController = Get.find<RecordingController>();
      await recordingController.setGuestName(_googleUserName!);

      Get.offAll(() => const HomeScreen());
    } catch (e) {
      Get.snackbar(
        l10n.errorOccurred,
        l10n.nameNotSaved,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _getContinueButtonText(AppLocalizations l10n) {
    if (isGoogleUserSignedIn && _googleUserName != null) {
      // Google user is authenticated, use their Google username
      return l10n.continueAs(_googleUserName!);
    } else {
      // Not authenticated, use the username from the text field
      final username = _usernameController.text.trim();
      if (username.isNotEmpty) {
        return l10n.continueAs(username);
      } else {
        // Username field is empty, show default guest text
        return l10n.continueAsGuest;
      }
    }
  }

  Future<void> _checkAgreementStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAgreed = prefs.getBool('has_agreed_to_terms') ?? false;
    final username = prefs.getString('username') ?? '';
    final hasSelectedLanguage = prefs.getString('selected_language') != null;

    if (hasAgreed && username.isNotEmpty && hasSelectedLanguage) {
      Get.offAll(() => const HomeScreen());
    }
  }

  Widget _buildLanguageOptions(AppLocalizations l10n) {
    return _buildCard(
      color: Colors.white.withValues(alpha: 0.95),
      child: Column(
        children: [
          for (final locale in languageController.supportedLocales)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  setState(() {
                    selectedLocale = locale;
                  });
                  languageController.changeLanguage(locale);
                  await Future.delayed(const Duration(milliseconds: 300));
                  await _saveAndProceed();
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selectedLocale?.languageCode == locale.languageCode
                        ? Colors.orange.shade100
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selectedLocale?.languageCode == locale.languageCode
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
                            fontWeight: selectedLocale?.languageCode ==
                                    locale.languageCode
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: selectedLocale?.languageCode ==
                                    locale.languageCode
                                ? Colors.orange.shade800
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (selectedLocale?.languageCode == locale.languageCode)
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
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLanguagePage(AppLocalizations l10n) {
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
                .animate(
                    onPlay: (controller) => controller.repeat(reverse: true))
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
                .animate(
                    onPlay: (controller) => controller.repeat(reverse: true))
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
                          _buildLanguageOptions(l10n)
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
                _buildPageIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage(AppLocalizations l10n) {
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
                  .animate(
                      onPlay: (controller) => controller.repeat(reverse: true))
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
                  .animate(
                      onPlay: (controller) => controller.repeat(reverse: true))
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
                      _buildCard(
                        padding: const EdgeInsets.all(20),
                        color: Colors.white.withValues(alpha: 0.95),
                        child: Column(
                          children: [
                            _buildFeatureItem(
                                Icons.library_music, l10n.appFeature1),
                            const SizedBox(height: 12),
                            _buildFeatureItem(
                                Icons.mic_rounded, l10n.appFeature2),
                            const SizedBox(height: 12),
                            _buildFeatureItem(
                                Icons.sync_rounded, l10n.appFeature3),
                            const SizedBox(height: 12),
                            _buildFeatureItem(
                                Icons.people_rounded, l10n.appFeature4),
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
                            _liquidController.animateToPage(
                                page: 2, duration: 600);
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
            _buildPageIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6366F1),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsPage(AppLocalizations l10n) {
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
// Background elements
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
                  .animate(
                      onPlay: (controller) => controller.repeat(reverse: true))
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
                  .animate(
                      onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(
                      duration: const Duration(seconds: 6),
                      begin: const Offset(1, 1),
                      end: const Offset(1.6, 1.6),
                      curve: Curves.easeInOut),
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
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
                          child: _buildCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.agreement,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildAgreementItem(l10n.term1),
                                const SizedBox(height: 8),
                                _buildAgreementItem(l10n.term2),
                                const SizedBox(height: 16),

                                // Agreement Checkbox
                                InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _agreementAccepted = !_agreementAccepted;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _agreementAccepted
                                          ? Colors.green.shade50
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _agreementAccepted
                                            ? Colors.green
                                            : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: _agreementAccepted
                                                ? Colors.green
                                                : Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: _agreementAccepted
                                                  ? Colors.green
                                                  : Colors.grey,
                                              width: 2,
                                            ),
                                          ),
                                          child: _agreementAccepted
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
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale(
                          delay: 200.ms,
                          duration: 400.ms,
                          curve: Curves.easeOut),

                      const SizedBox(height: 20),

                      // Username Input (only shown when agreement is accepted and not signed in with Google)
                      if (_agreementAccepted && !isGoogleUserSignedIn) ...[
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          child: TextField(
                            controller: _usernameController,
                            maxLength: 15, // Limit to 15 characters
                            style: const TextStyle(
                                fontSize: 15, color: Colors.black),
                            decoration: InputDecoration(
                              labelText: l10n.enterYourName,
                              labelStyle: const TextStyle(
                                  color: Colors.green, fontSize: 14),
                              prefixIcon: const Icon(Icons.person_outline,
                                  color: Colors.green, size: 22),
                              border: InputBorder.none,
                              counterText: '', // Hide the default counter
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
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
                          child: Text(
                            '${_usernameController.text.trim().length}/15 characters (minimum 4)',
                            style: TextStyle(
                              fontSize: 12,
                              color: _usernameController.text.trim().length >= 4
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // Debug info (temporary)
                        if (kDebugMode) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Debug Info:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Agreement: $_agreementAccepted',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.red),
                                ),
                                Text(
                                  'Google signed in: $isGoogleUserSignedIn',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.red),
                                ),
                                Text(
                                  'Username length: ${_usernameController.text.trim().length}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.red),
                                ),
                                Text(
                                  'Show Google btn: ${_agreementAccepted && !isGoogleUserSignedIn && _usernameController.text.trim().length >= 4}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.red),
                                ),
                                Text(
                                  'Show Continue btn: ${_agreementAccepted && (isGoogleUserSignedIn || _usernameController.text.trim().length >= 4)}',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],

                      // Google Sign In Button (only shown when agreement is accepted, username is filled with 4+ chars, and not signed in)
                      if (_agreementAccepted &&
                          !isGoogleUserSignedIn &&
                          _usernameController.text.trim().length >= 4) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                !_isSigningIn ? _handleGoogleSignIn : null,
                            icon: _isSigningIn
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Image.asset(
                                    'assets/images/google_logo.png',
                                    height: 24,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.login, size: 24),
                                  ),
                            label: Text(
                              _isSigningIn
                                  ? l10n.signingIn
                                  : l10n.signInWithGoogle,
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
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 600.ms)
                            .scale(
                                delay: 400.ms,
                                duration: 400.ms,
                                curve: Curves.easeOutBack),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
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

                      // Continue Button (shown when agreement is accepted)
                      if (_agreementAccepted) ...[
                        // User Info Display (when Google user is signed in)
                        if (isGoogleUserSignedIn)
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      Text(
                                        _googleUserName!,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (_googleUserEmail != null)
                                        Text(
                                          _googleUserEmail!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 600.ms)
                              .slideY(
                                  begin: 0.2, end: 0, curve: Curves.easeOut),

                        if (isGoogleUserSignedIn ||
                            _usernameController.text.trim().length >= 4)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: !_isSigningIn
                                  ? isGoogleUserSignedIn
                                      ? _handleGoogleUserContinue
                                      : _usernameController.text
                                                  .trim()
                                                  .length >=
                                              4
                                          ? () async {
                                              await _handleUsernameSubmit();
                                            }
                                          : null
                                  : null,
                              icon: isGoogleUserSignedIn
                                  ? const Icon(Icons.check_circle, size: 20)
                                  : const Icon(Icons.person_outline, size: 20),
                              label: Text(
                                _getContinueButtonText(l10n),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _usernameController.text.trim().length >=
                                                4 ||
                                            isGoogleUserSignedIn
                                        ? Colors.white
                                        : Colors.grey.shade300,
                                foregroundColor:
                                    _usernameController.text.trim().length >=
                                                4 ||
                                            isGoogleUserSignedIn
                                        ? Colors.green.shade700
                                        : Colors.grey.shade600,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation:
                                    _usernameController.text.trim().length >=
                                                4 ||
                                            isGoogleUserSignedIn
                                        ? 8
                                        : 0,
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(
                                  delay: isGoogleUserSignedIn ? 400.ms : 600.ms,
                                  duration: 600.ms)
                              .scale(
                                  delay: isGoogleUserSignedIn ? 400.ms : 600.ms,
                                  duration: 400.ms,
                                  curve: Curves.easeOutBack),
                      ],

                      const SizedBox(height: 60), // Space for page indicator
                    ],
                  ),
                ),
              ),
            ),
            _buildPageIndicator(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final pages = [
      _buildLanguagePage(l10n),
      _buildWelcomePage(l10n),
      _buildTermsPage(l10n),
    ];

    return PopScope(
      canPop: false, // Don't allow exiting the app from intro
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentPage > 0) {
          // Navigate to previous page if not on first page
          _liquidController.animateToPage(
              page: _currentPage - 1, duration: 600);
        }
      },
      child: Scaffold(
        body: LiquidSwipe(
          pages: pages,
          liquidController: _liquidController,
          onPageChangeCallback: (activePageIndex) {
            setState(() {
              _currentPage = activePageIndex;
            });

            // Prevent going forward from the last page (terms page)
            if (activePageIndex >= 2) {
              // User tried to swipe forward from last page, go back
              Future.delayed(const Duration(milliseconds: 100), () {
                if (_currentPage > 2) {
                  _liquidController.jumpToPage(page: 2);
                }
              });
            }
          },
          waveType: WaveType.liquidReveal,
          enableLoop: false,
          slideIconWidget: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          positionSlideIcon: 0.2,
          enableSideReveal: true,
          ignoreUserGestureWhileAnimating: true,
          disableUserGesture: false,
        ),
      ),
    );
  }

  Widget _buildAgreementItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
