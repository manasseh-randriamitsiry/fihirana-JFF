import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fihirana/controller/auth_controller.dart';
import 'package:fihirana/widgets/common/banned_page.dart';

class SecurityService extends GetxService {
  static SecurityService get instance => Get.find<SecurityService>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Security check status
  final RxBool _isSecurityChecked = false.obs;
  final RxBool _isUserBlocked = false.obs;
  final RxString _blockReason = ''.obs;
  final RxBool _isPermanentlyBlocked = false.obs;

  // Timer for periodic security checks
  Timer? _securityTimer;

  bool get isSecurityChecked => _isSecurityChecked.value;
  bool get isUserBlocked => _isUserBlocked.value;
  String get blockReason => _blockReason.value;
  bool get isPermanentlyBlocked => _isPermanentlyBlocked.value;

  @override
  Future<void> onInit() async {
    super.onInit();

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // Wait for auth to fully initialize
        await Future.delayed(const Duration(milliseconds: 1000));
        await _performSecurityCheck();
      } else {
        _resetSecurityStatus();
      }
    });

    // Also perform initial check if user is already logged in
    if (_auth.currentUser != null) {
      await Future.delayed(const Duration(milliseconds: 2000));
      await _performSecurityCheck();
    }

    // Start periodic security checks every 30 seconds
    _startPeriodicSecurityCheck();
  }

  void _startPeriodicSecurityCheck() {
    _securityTimer?.cancel();
    _securityTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_auth.currentUser != null) {
        await _performSecurityCheck();
      }
    });
  }

  @override
  void onClose() {
    _securityTimer?.cancel();
    super.onClose();
  }

  Future<void> _performSecurityCheck() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        _resetSecurityStatus();
        return;
      }

      if (kDebugMode) {
        print('🔒 Performing security check for: ${currentUser.email}');
      }

      // Get user document from Firestore with timeout
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));

      if (!userDoc.exists) {
        if (kDebugMode) print('🔒 User document does not exist');
        _resetSecurityStatus();
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final isDisabled = userData['disabled'] as bool? ?? false;
      final isPermanentlyBlocked =
          userData['permanentlyBlocked'] as bool? ?? false;
      final isAdmin = userData['isAdmin'] as bool? ?? false;
      final blockedReason =
          userData['blockedReason'] as String? ?? 'Account suspended';

      // SECURITY: Admin privileges do not override ban status
      // Ban status ALWAYS overrides admin privileges
      final wasBlocked = _isUserBlocked.value;
      _isUserBlocked.value = isDisabled || isPermanentlyBlocked;
      _isPermanentlyBlocked.value = isPermanentlyBlocked;
      _blockReason.value = blockedReason;
      _isSecurityChecked.value = true;

      // Log security check for debugging
      if (kDebugMode) {
        print('🔒 Security Check Results:');
        print('   User: ${currentUser.email}');
        print('   Admin: $isAdmin');
        print('   Disabled: $isDisabled');
        print('   Permanently Blocked: $isPermanentlyBlocked');
        print('   Was Blocked: $wasBlocked');
        print('   Now Blocked: ${_isUserBlocked.value}');
        print(
            '   Final Status: ${_isUserBlocked.value ? "🚫 BLOCKED" : "✅ ALLOWED"}');
        if (_isUserBlocked.value) {
          print('   ⚠️ Ban status overrides admin privileges!');
        }
      }

      // If user is blocked (regardless of any admin status), trigger immediate action
      if (_isUserBlocked.value && !wasBlocked) {
        if (kDebugMode) print('🚨 User just got blocked! Taking action...');
        await _handleBlockedUser();
      } else if (_isUserBlocked.value && wasBlocked) {
        if (kDebugMode) print('🔄 User still blocked, maintaining ban...');
        // Ensure user stays signed out
        await _ensureUserStaysSignedOut();
      }
    } catch (e) {
      if (kDebugMode) print('🔒 Security check error: $e');
      // Don't reset status on error, keep previous state
    }
  }

  Future<void> _ensureUserStaysSignedOut() async {
    try {
      // Double check user is still signed out
      if (_auth.currentUser != null) {
        if (kDebugMode) print('🔒 Forcing sign out for blocked user...');
        final AuthController authController = Get.find<AuthController>();
        await authController.signOut();
      }
    } catch (e) {
      if (kDebugMode) print('🔒 Error ensuring sign out: $e');
    }
  }

  Future<void> _handleBlockedUser() async {
    // Sign out user immediately
    try {
      // Clear any stored auth state using AuthController's signOut method
      final AuthController authController = Get.find<AuthController>();
      await authController.signOut();

      // Navigate to banned page
      Get.offAll(() => const BannedPage(), transition: Transition.fadeIn);
    } catch (e) {
      if (kDebugMode) {
        print('Error handling blocked user: $e');
      }
      // Fallback: just navigate to banned page
      Get.offAll(() => const BannedPage(), transition: Transition.fadeIn);
    }
  }

  void _resetSecurityStatus() {
    _isSecurityChecked.value = false;
    _isUserBlocked.value = false;
    _isPermanentlyBlocked.value = false;
    _blockReason.value = '';
  }

  // Public method to manually trigger security check
  Future<void> checkUserSecurity() async {
    if (kDebugMode) print('🔒 Manual security check triggered');
    await _performSecurityCheck();
  }

  // Check if an email is blocked (for Google Drive users)
  Future<bool> isEmailBlocked(String email) async {
    try {
      if (kDebugMode) {
        print('🔒 Checking if email is blocked: $email');
      }

      // Check blocked emails collection first
      final blockedEmailDoc = await _firestore
          .collection('blocked_emails')
          .doc(email.toLowerCase().trim())
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));

      if (blockedEmailDoc.exists) {
        if (kDebugMode) {
          print('🔒 Email found in blocked_emails collection: $email');
        }
        return true;
      }

      // Also check users collection in case user has Firebase document
      final userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        final isDisabled = userData['disabled'] as bool? ?? false;
        final isPermanentlyBlocked =
            userData['permanentlyBlocked'] as bool? ?? false;

        if (kDebugMode) {
          print(
              '🔒 Email found in users collection - disabled: $isDisabled, permanentlyBlocked: $isPermanentlyBlocked');
        }

        return isDisabled || isPermanentlyBlocked;
      }

      if (kDebugMode) {
        print('🔒 Email not found in any block list: $email');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('🔒 Error checking blocked email: $e');
      }
      // On error, allow access (fail-safe)
      return false;
    }
  }

  // Force immediate security check for specific user (admin use)
  Future<void> forceSecurityCheckForUser(String userId) async {
    try {
      if (kDebugMode) print('🔒 Force security check for user: $userId');

      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 10));

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final isDisabled = userData['disabled'] as bool? ?? false;
        final isPermanentlyBlocked =
            userData['permanentlyBlocked'] as bool? ?? false;

        if (kDebugMode) {
          print('🔒 Force check results for $userId:');
          print('   Disabled: $isDisabled');
          print('   Permanently Blocked: $isPermanentlyBlocked');
          print('   Should be blocked: ${isDisabled || isPermanentlyBlocked}');
        }

        // If this user is currently logged in and should be blocked
        if (_auth.currentUser?.uid == userId &&
            (isDisabled || isPermanentlyBlocked)) {
          if (kDebugMode) {
            debugPrint('🚨 Current user should be blocked! Taking action...');
          }
          await _handleBlockedUser();
        }
      }
    } catch (e) {
      if (kDebugMode) print('🔒 Force security check error: $e');
    }
  }

  // Method to force app exit (for extreme cases)
  Future<void> forceAppExit() async {
    if (GetPlatform.isAndroid) {
      // For Android, we can use SystemNavigator.pop()
      // Note: This requires importing 'package:flutter/services.dart'
      try {
        await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      } catch (e) {
        if (kDebugMode) {
          print('Error exiting app: $e');
        }
      }
    } else if (GetPlatform.isIOS) {
      // For iOS, we can't force exit, so we just show the banned page
      Get.offAll(() => const BannedPage(), transition: Transition.fadeIn);
    }
  }
}
