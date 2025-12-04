import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fihirana/features/recording/presentation/controllers/recording_controller.dart';
import 'package:fihirana/features/home/presentation/pages/home_screen.dart';

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
    usernameLength.value = usernameController.text.trim().length;
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

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setBool('isFirstTime', false);

    // Set guest name for recording
    final recordingController = Get.find<RecordingController>();
    recordingController.setGuestName(username);

    // Navigate to home
    await Future.delayed(const Duration(milliseconds: 300));
    Get.offAll(() => const HomeScreen());
  }

  /// Check if username is valid for submission
  bool get canSubmit => usernameController.text.trim().length >= 4 &&
                        usernameController.text.trim().length <= 15;
}