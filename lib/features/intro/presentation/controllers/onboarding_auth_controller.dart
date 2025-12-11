import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/features/home/presentation/pages/home_screen.dart';
import 'package:fihirana/core/error/error_handler.dart';

/// Controller for authentication during onboarding
class OnboardingAuthController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  final RxBool isSigningIn = false.obs;
  final RxString googleUserName = ''.obs;
  final RxString googleUserEmail = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _setupAuthListeners();
  }

  void _setupAuthListeners() {
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

  /// Handle Google sign in
  Future<void> handleGoogleSignIn() async {
    if (isSigningIn.value) return;

    isSigningIn.value = true;

    try {
      final userCredential = await _authController.signInWithGoogle();

      if (userCredential == null) {
        isSigningIn.value = false;
        return;
      }

      isSigningIn.value = false;

      // Show success message
      Get.snackbar(
        'Welcome',
        'Connected as ${userCredential.displayName ?? userCredential.email}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      await Future.delayed(const Duration(milliseconds: 1500));
    } catch (e) {
      ErrorHandler.handleError(e, message: 'googleSignInFailed'.tr);
      isSigningIn.value = false;
    }
  }

  /// Handle Google user continuation
  Future<void> handleGoogleUserContinue() async {
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
      ErrorHandler.handleError(e, message: 'nameNotSaved'.tr);
    }
  }
}