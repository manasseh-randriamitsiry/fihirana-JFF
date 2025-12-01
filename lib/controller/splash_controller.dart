import 'package:fihirana/controller/recording_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import '../screen/accueil/home_screen.dart';
import 'auth_controller.dart';
import 'language_controller.dart';

class SplashController extends GetxController {
  static SplashController get to => Get.find();

  // Form controllers
  final TextEditingController usernameController = TextEditingController();

  // State variables
  final RxBool agreementAccepted = false.obs;
  final RxBool termsExpanded = false.obs;
  final RxInt currentPage = 0.obs;
  final RxBool isSigningIn = false.obs;
  final RxString googleUserName = ''.obs;
  final RxString googleUserEmail = ''.obs;
  final Rx<Locale?> selectedLocale = Rx<Locale?>(null);
  final RxInt usernameLength = 0.obs;

  // Controllers
  late final LanguageController languageController;
  late final LiquidController liquidController;

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
    _setupListeners();
    _checkAgreementStatus();
  }

  @override
  void onClose() {
    usernameController.dispose();
    super.onClose();
  }

  void _initializeControllers() {
    languageController = Get.find<LanguageController>();
    selectedLocale.value = languageController.currentLocaleValue;
    liquidController = LiquidController();

    // Add listener to username controller
    usernameController.addListener(() {
      usernameLength.value = usernameController.text.trim().length;
    });
  }

  void _setupListeners() {
    // Listen to Firebase auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        googleUserName.value = user.displayName ?? user.email?.split('@')[0] ?? '';
        googleUserEmail.value = user.email ?? '';
      } else {
        googleUserName.value = '';
        googleUserEmail.value = '';
      }
    });
  }

  bool get isGoogleUserSignedIn =>
      googleUserName.value.isNotEmpty && googleUserEmail.value.isNotEmpty;

  Future<void> saveAndProceed() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenLanguageSelection', true);

    // Animate to next page
    await liquidController.animateToPage(page: 1, duration: 600);
  }

  Future<void> handleGoogleSignIn() async {
    if (isSigningIn.value) return;

    isSigningIn.value = true;
    HapticFeedback.mediumImpact();

    try {
      final authController = Get.find<AuthController>();
      final userCredential = await authController.signInWithGoogle();

      if (userCredential == null) {
        isSigningIn.value = false;
        return;
      }

      isSigningIn.value = false;

      // Show success message
      Get.snackbar(
        'Welcome',
        'Connected as ${userCredential.user?.displayName ?? userCredential.user?.email}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      await Future.delayed(const Duration(milliseconds: 1500));
    } catch (e) {
      Get.snackbar(
        'Error',
        'Google sign in failed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isSigningIn.value = false;
    }
  }

  Future<void> handleUsernameSubmit() async {
    HapticFeedback.mediumImpact();

    final username = usernameController.text.trim();

    if (username.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter your name',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    if (username.length < 4 || username.length > 15) {
      Get.snackbar(
        'Error',
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

      if (kDebugMode) {
        print('✅ Splash: Saved username to SharedPreferences: $username');
        final savedUsername = prefs.getString('username');
        print('✅ Splash: Verified saved username: $savedUsername');
      }

      final recordingController = Get.find<RecordingController>();
      recordingController.setGuestName(username);

      await Future.delayed(const Duration(milliseconds: 300));

      Get.offAll(() => const HomeScreen());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Name not saved',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> handleGoogleUserContinue() async {
    HapticFeedback.mediumImpact();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', googleUserName.value);
      await prefs.setString('email', googleUserEmail.value);
      await prefs.setBool('has_agreed_to_terms', true);
      await prefs.setBool('isFirstTime', false);
      await prefs.setBool('is_google_user', true);

      final recordingController = Get.find<RecordingController>();
      recordingController.setGuestName(googleUserName.value);

      await Future.delayed(const Duration(milliseconds: 300));

      Get.offAll(() => const HomeScreen());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Name not saved',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String getContinueButtonText(String continueAs, String continueAsGuest) {
    if (isGoogleUserSignedIn && googleUserName.value.isNotEmpty) {
      return continueAs;
    } else {
      final username = usernameController.text.trim();
      if (username.isNotEmpty) {
        return continueAs;
      } else {
        return continueAsGuest;
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

  void updatePage(int page) {
    currentPage.value = page;
  }

  void toggleAgreement() {
    agreementAccepted.value = !agreementAccepted.value;
  }

  void toggleTermsExpanded() {
    termsExpanded.value = !termsExpanded.value;
  }

  void selectLanguage(Locale locale) async {
    HapticFeedback.selectionClick();
    selectedLocale.value = locale;
    languageController.changeLanguage(locale);
    await Future.delayed(const Duration(milliseconds: 300));
    await saveAndProceed();
  }
}

