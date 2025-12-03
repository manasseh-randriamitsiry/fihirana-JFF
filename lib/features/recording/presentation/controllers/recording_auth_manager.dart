import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:fihirana/features/recording/data/services/google_drive_service.dart';
import 'package:fihirana/core/security/security_service.dart';
import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';

/// Manages authentication and user-related operations
class RecordingAuthManager extends GetxController {
  GoogleDriveService? _driveService;

  // Drive state
  final RxBool isDriveSignedIn = false.obs;
  final Rxn<String> userEmail = Rxn<String>();
  final RxString guestName = ''.obs;

  // Audio sharing permission
  final RxBool allowToShareAudio = false.obs;

  // Storage quota state
  final Rx<drive.AboutStorageQuota?> storageQuota =
      Rx<drive.AboutStorageQuota?>(null);

  // Error tracking
  final RxString lastError = ''.obs;

  // Callback for triggering sync after validation
  Future<void> Function()? onDriveSignInSuccess;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _initializeDriveService();
      await _loadGuestName();
      await _loadShareAudioPreference();
    } catch (e) {
      if (kDebugMode) {
        print('RecordingAuthManager: Initialization error: $e');
      }
      lastError.value = 'Initialization failed: $e';
    }
  }

  Future<void> _initializeDriveService() async {
    try {
      final authController = Get.find<AuthController>();
      _driveService = authController.driveService;
      if (kDebugMode) {
        print(
            'RecordingAuthManager: Drive service initialized from AuthController');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RecordingAuthManager: Error initializing Drive service: $e');
      }
      lastError.value = 'Drive service initialization failed: $e';
    }
  }

  Future<void> _loadGuestName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      guestName.value = prefs.getString('guest_name') ?? '';
    } catch (e) {
      if (kDebugMode) {
        print('RecordingAuthManager: Error loading guest name: $e');
      }
    }
  }

  Future<void> _loadShareAudioPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      allowToShareAudio.value = prefs.getBool('allowToShareAudio') ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('RecordingAuthManager: Error loading share audio preference: $e');
      }
    }
  }

  Future<void> setShareAudioPreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('allowToShareAudio', value);
      allowToShareAudio.value = value;
    } catch (e) {
      if (kDebugMode) {
        print('RecordingAuthManager: Error setting share audio preference: $e');
      }
    }
  }

  Future<void> setGuestName(String name) async {
    try {
      guestName.value = name;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('guest_name', name);
    } catch (e) {
      if (kDebugMode) {
        print('RecordingAuthManager: Error setting guest name: $e');
      }
    }
  }

  // Drive authentication methods
  Future<void> signInToDrive() async {
    try {
      if (_driveService == null) {
        throw Exception('Drive service not initialized');
      }
      final account = await _driveService!.signIn();
      if (account != null) {
        await validateDriveUser(account);
        await fetchStorageQuota();
      }
    } catch (e) {
      if (kDebugMode) {
        print('RecordingAuthManager: Error signing in to Drive: $e');
      }
      Get.snackbar(
        'Sign In Failed',
        'Failed to sign in to Google Drive: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> signOutFromDrive() async {
    try {
      if (_driveService != null) {
        await _driveService!.signOut();
      }
      isDriveSignedIn.value = false;
      userEmail.value = null;
      storageQuota.value = null;

      Get.snackbar(
        'Signed Out',
        'Signed out from Google Drive',
        backgroundColor: Colors.grey[800],
        colorText: Colors.white,
      );
    } catch (e) {
      if (kDebugMode) {
        print('RecordingAuthManager: Error signing out from Drive: $e');
      }
    }
  }

  /// Validates Drive user and sets permissions
  Future<void> validateDriveUser(GoogleSignInAccount user) async {
    try {
      final securityService = SecurityService.instance;
      final isEmailBanned = await securityService.isEmailBlocked(user.email);

      if (isEmailBanned) {
        if (kDebugMode) {
          print(
              'RecordingAuthManager: Email ${user.email} is banned, denying access');
        }

        if (_driveService != null) {
          await _driveService!.signOut();
        }
        isDriveSignedIn.value = false;
        userEmail.value = null;
        await setShareAudioPreference(false);

        if (Get.context != null) {
          Get.snackbar(
            'Access Denied',
            'This email is not allowed to share audio content.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      isDriveSignedIn.value = true;
      userEmail.value = user.email;
      await setShareAudioPreference(true);

      if (kDebugMode) {
        print('RecordingAuthManager: Validated Drive account: ${user.email}');
        print('RecordingAuthManager: Audio sharing enabled');
      }

      // Trigger sync callback if provided
      if (onDriveSignInSuccess != null) {
        await onDriveSignInSuccess!();
      }
    } catch (e) {
      if (kDebugMode) {
        print('RecordingAuthManager: Error validating Drive user: $e');
      }
      lastError.value = 'Drive user validation failed: $e';
    }
  }

  /// Check if current user is allowed to record
  Future<bool> checkUserCanRecord() async {
    final securityService = SecurityService.instance;

    final isFirebaseAuthenticated = FirebaseAuth.instance.currentUser != null;
    final isGoogleDriveAuthenticated = _driveService?.currentUser != null;

    if (isFirebaseAuthenticated) {
      await securityService.checkUserSecurity();
      if (securityService.isUserBlocked) {
        if (kDebugMode) {
          print('🚫 Blocked Firebase user attempted to record/publish');
        }
        Get.snackbar(
          'Access Denied',
          'Your account has been restricted. Recording and publishing features are not available.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return false;
      }
    }

    if (isGoogleDriveAuthenticated) {
      final googleUserEmail = _driveService?.currentUser?.email;
      if (googleUserEmail != null) {
        final isEmailBlocked =
            await securityService.isEmailBlocked(googleUserEmail);
        if (isEmailBlocked) {
          if (kDebugMode) {
            print(
                '🚫 Blocked Google Drive user attempted to record/publish: $googleUserEmail');
          }
          Get.snackbar(
            'Access Denied',
            'Your account has been restricted. Recording and publishing features are not available.',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
          );
          return false;
        }
      }
    }

    return true;
  }

  Future<void> fetchStorageQuota() async {
    if (!isDriveSignedIn.value) return;

    try {
      final quota = await _driveService!.getStorageQuota();
      storageQuota.value = quota;
    } catch (e) {
      if (kDebugMode) {
        print('RecordingAuthManager: Error fetching storage quota: $e');
      }
    }
  }

  /// Check Drive authentication status
  Future<GoogleSignInAccount?> checkDriveAuthentication() async {
    try {
      if (_driveService == null) {
        if (kDebugMode) {
          print('RecordingAuthManager: Drive service is null');
        }
        return null;
      }

      // Check if already signed in
      final currentUser = _driveService!.currentUser;
      if (currentUser != null) {
        if (kDebugMode) {
          print(
              'RecordingAuthManager: Found existing Drive user: ${currentUser.email}');
        }
        return currentUser;
      }

      // Try silent sign-in
      final silentUser = await _driveService!.signInSilently();
      if (silentUser != null) {
        if (kDebugMode) {
          print(
              'RecordingAuthManager: Silent sign-in successful: ${silentUser.email}');
        }
        return silentUser;
      }

      if (kDebugMode) {
        print('RecordingAuthManager: No Drive authentication found');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('RecordingAuthManager: Error checking Drive authentication: $e');
      }
      lastError.value = 'Drive authentication check failed: $e';
      return null;
    }
  }

  /// Check for silent sign-in
  Future<void> checkForSilentSignIn() async {
    try {
      if (_driveService == null) return;
      final currentUser = await _driveService!.signInSilently();
      if (currentUser != null) {
        if (kDebugMode) {
          print(
              'RecordingAuthManager: Periodic check found Drive account: ${currentUser.email}');
        }
        await validateDriveUser(currentUser);
      }
    } catch (e) {
      if (kDebugMode) {
        print('RecordingAuthManager: Periodic silent sign-in check failed: $e');
      }
    }
  }

  // Getters for drive service access
  GoogleDriveService? get driveService => _driveService;
  GoogleSignInAccount? get currentUser => _driveService?.currentUser;
}
