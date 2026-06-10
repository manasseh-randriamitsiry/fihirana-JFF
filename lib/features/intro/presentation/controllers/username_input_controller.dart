import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/features/home/presentation/pages/home_screen.dart';
import 'package:fihirana/core/controllers/user_controller.dart';

/// Controller for username input and validation
class UsernameInputController extends GetxController {
  final TextEditingController usernameController = TextEditingController();
  final RxInt usernameLength = 0.obs;

  @override
  void onInit() {
    super.onInit();
    usernameController.addListener(_updateUsernameLength);
  }

  @override
  void onClose() {
    usernameController.removeListener(_updateUsernameLength);
    usernameController.dispose();
    super.onClose();
  }

  void _updateUsernameLength() {
    final length = usernameController.text.trim().length;
    usernameLength.value = length;
    if (kDebugMode) {
      print(
          'UsernameInputController: Text changed, length: $length, canSubmit: $canSubmit');
    }
  }

  /// Validate username
  String? validateUsername(String? value) {
    final username = value?.trim() ?? '';

    if (username.isEmpty) {
      return 'Please enter your name';
    }

    if (username.length < 4 || username.length > 15) {
      return 'Name must be between 4 and 15 characters';
    }

    return null; // Valid
  }

  /// Submit username and proceed
  Future<void> submitUsername() async {
    final username = usernameController.text.trim();

    // Save to preferences and update reactive controller
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setBool('isFirstTime', false);

    // Update the reactive user controller
    final userController = Get.find<UserController>();
    await userController.setUsername(username);

    // Set guest name for recording
    final recordingController = Get.find<RecordingController>();
    recordingController.setGuestName(username);

    // Navigate to home
    await Future.delayed(const Duration(milliseconds: 300));
    Get.offAll(() => const HomeScreen());
  }

  /// Check if username is valid for submission
  bool get canSubmit {
    final length = usernameController.text.trim().length;
    final result = length >= 4 && length <= 15;
    if (kDebugMode) {
      print(
          'UsernameInputController: canSubmit check - length: $length, result: $result');
    }
    return result;
  }
}
