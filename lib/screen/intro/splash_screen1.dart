import 'package:fihirana/screen/accueil/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import '../../l10n/app_localizations.dart';
import '../../controller/language_controller.dart';
import '../../controller/recording_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({super.key});

  @override
  State<SplashScreen1> createState() => _SplashScreen1State();
}

class _SplashScreen1State extends State<SplashScreen1> {
  final TextEditingController _usernameController = TextEditingController();
  bool _agreementAccepted = false;
  int _currentPage = 0;

  // Language selection state variables
  late final LanguageController languageController;
  Locale? selectedLocale;

  // Liquid swipe controller
  late LiquidController _liquidController;

  @override
  void initState() {
    super.initState();
    _checkAgreementStatus();

    // Initialize language controller
    languageController = Get.find<LanguageController>();
    selectedLocale = languageController.currentLocaleValue;

    // Initialize liquid swipe controller
    _liquidController = LiquidController();
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
            Color(0xFF4A90E2),
            Color(0xFF357ABD),
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Background elements
            Positioned(
              top: 50,
              left: 20,
              child: Icon(
                Icons.music_note,
                size: 40,
                color: Colors.white.withValues(alpha: 0.2),
              )
                  .animate(
                      onPlay: (controller) => controller.repeat(reverse: true))
                  .moveY(
                      begin: 0,
                      end: -20,
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut),
            ),
            Positioned(
              bottom: 100,
              right: 30,
              child: Icon(
                Icons.library_music,
                size: 60,
                color: Colors.white.withValues(alpha: 0.15),
              )
                  .animate(
                      onPlay: (controller) => controller.repeat(reverse: true))
                  .moveY(
                      begin: 0,
                      end: 30,
                      duration: const Duration(seconds: 3),
                      curve: Curves.easeInOut),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          size: 80,
                          color: Color(0xFF4A90E2),
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
                              duration: 1500.ms, color: Colors.blue.shade100),
                      const SizedBox(height: 40),
                      _buildCard(
                        child: Column(
                          children: [
                            Text(
                              l10n.splashScreenTitle,
                              style: const TextStyle(
                                fontSize: 26,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16.0),
                            Text(
                              l10n.splashScreenSubtitle,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _liquidController.animateToPage(
                              page: 2, duration: 600);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4A90E2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                          shadowColor: Colors.black.withValues(alpha: 0.3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.continueText,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded),
                          ],
                        ),
                      ).animate().fadeIn(delay: 800.ms, duration: 600.ms).scale(
                          delay: 800.ms,
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

  Widget _buildTermsPage(AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF66BB6A),
            Color(0xFF43A047),
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Background elements
            Positioned(
              top: -50,
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
                      duration: const Duration(seconds: 4),
                      begin: const Offset(1, 1),
                      end: const Offset(1.3, 1.3),
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

                      // Username Input
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
                          style: const TextStyle(
                              fontSize: 15, color: Colors.black),
                          decoration: InputDecoration(
                            labelText: l10n.enterYourName,
                            labelStyle: const TextStyle(
                                color: Colors.green, fontSize: 14),
                            prefixIcon: const Icon(Icons.person_outline,
                                color: Colors.green, size: 22),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

                      const SizedBox(height: 16),

                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _agreementAccepted
                              ? () async {
                                  await _handleUsernameSubmit();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _agreementAccepted
                                ? Colors.white
                                : Colors.grey.shade300,
                            foregroundColor: _agreementAccepted
                                ? Colors.green
                                : Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: _agreementAccepted ? 8 : 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.continueText,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      )
                          .animate(target: _agreementAccepted ? 1 : 0)
                          .shimmer(
                              duration: 1500.ms, color: Colors.green.shade100)
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 600.ms)
                          .scale(
                              delay: 600.ms,
                              duration: 400.ms,
                              curve: Curves.easeOutBack),

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
