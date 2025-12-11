import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

import 'package:fihirana/features/recording/data/services/google_drive_service.dart';
import 'package:fihirana/core/security/security_service.dart';
import 'package:fihirana/core/error/error_handler.dart';
import 'package:fihirana/features/auth/domain/usecases/sign_in_with_google_usecase.dart';

import 'package:fihirana/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:fihirana/features/auth/domain/usecases/ensure_user_document_exists_usecase.dart';
import 'package:fihirana/features/auth/domain/entities/user.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  late final GoogleSignIn googleSignIn;

  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final SignOutUseCase _signOutUseCase;
  final EnsureUserDocumentExistsUseCase _ensureUserDocumentExistsUseCase;
  final RxBool _canAddSongs = false.obs;
  final RxBool _isAdmin = false.obs;
  final RxBool _isSuperAdmin = false.obs;
  final RxInt _addedHymnsCount = 0.obs;
  final RxInt _monthlyHymnCount = 0.obs;
  final RxString _lastHymnAdditionMonth = ''.obs;
  StreamSubscription<DocumentSnapshot>? _permissionSubscription;
  late GoogleDriveService _driveService;

  AuthController({
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required SignOutUseCase signOutUseCase,
    required EnsureUserDocumentExistsUseCase ensureUserDocumentExistsUseCase,
  })  : _signInWithGoogleUseCase = signInWithGoogleUseCase,
        _signOutUseCase = signOutUseCase,
        _ensureUserDocumentExistsUseCase = ensureUserDocumentExistsUseCase {
    googleSignIn = Get.find<GoogleSignIn>();
  }

  bool get canAddSongs => _canAddSongs.value;
  bool get isAdmin => _isAdmin.value;
  bool get isSuperAdmin => _isSuperAdmin.value;
  int get addedHymnsCount => _addedHymnsCount.value;
  bool get isAuthenticated => _auth.currentUser != null;

  int get effectiveMonthlyHymnCount {
    final currentMonth = DateTime.now().toString().substring(0, 7); // YYYY-MM
    if (_lastHymnAdditionMonth.value != currentMonth) {
      return 0;
    }
    return _monthlyHymnCount.value;
  }

  int get remainingHymnsThisMonth => 5 - effectiveMonthlyHymnCount;

  GoogleDriveService get driveService => _driveService;

  @override
  void onInit() {
    super.onInit();

    // Initialize Google Drive service with shared GoogleSignIn instance
    _driveService = Get.find<GoogleDriveService>();
    _driveService.initialize(googleSignIn);

    _auth.authStateChanges().listen((firebase_auth.User? user) async {
      if (user != null) {
        _updateUserPermissions(user);

// Ensure user document exists
        await _ensureUserDocumentExistsUseCase();

        // Automatically sign in to Google Drive when Firebase auth state changes
        try {
          final account = await _driveService.signIn();
          if (account != null) {
            // Check if email is banned before allowing auto sign-in
            final securityService = SecurityService.instance;
            final isEmailBanned =
                await securityService.isEmailBlocked(account.email);

            if (isEmailBanned) {
              if (kDebugMode) {
                print(
                    '🚫 Auto sign-in blocked for banned email: ${account.email}');
              }
              // Sign out immediately
              await _driveService.signOut();
            } else {
              if (kDebugMode) {
                print(
                    '✅ Auto-signed in to Google Drive for user: ${user.displayName}');
              }
            }
          }
        } catch (driveError) {
          ErrorHandler.handleError(driveError, message: 'errorOccurred'.tr);
        }
      } else {
        _permissionSubscription?.cancel();
        _permissionSubscription = null;
        _canAddSongs.value = false;
        _isAdmin.value = false;
        _isSuperAdmin.value = false;

        // Sign out from Google Drive when Firebase signs out
        try {
          await _driveService.signOut();
        } catch (e) {
          ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
        }
      }
    });
  }

  @override
  void onClose() {
    _permissionSubscription?.cancel();
    super.onClose();
  }

  void _updateUserPermissions(firebase_auth.User user) {
    // Cancel existing subscription if any
    _permissionSubscription?.cancel();

    // Set up real-time listener for all users
    _permissionSubscription =
        _firestore.collection('users').doc(user.uid).snapshots().listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();

          // Strict boolean check for isAdmin
          final dynamic isAdminData = data?['isAdmin'];
          final bool isAdminDb = isAdminData == true;

// Check isSuperAdmin from DB and Hardcoded Email
          final bool isSuperAdminDb = data?['isSuperAdmin'] == true;
          final bool isSuperAdminEmail =
              user.email == 'manassehrandriamitsiry@gmail.com';
          final bool isSuperAdmin = isSuperAdminDb || isSuperAdminEmail;

          _isAdmin.value = isAdminDb || isSuperAdmin;
          _isSuperAdmin.value = isSuperAdmin;

          // canAddSongs is true by default for new users, so we trust the DB value
          // If it's missing (null), we default to false, unless it's the super admin
          _canAddSongs.value = (data?['canAddSongs'] ?? false) || isSuperAdmin;

          _addedHymnsCount.value = (data?['addedHymnsCount'] ?? 0) as int;
          _monthlyHymnCount.value = (data?['monthlyHymnCount'] ?? 0) as int;
          _lastHymnAdditionMonth.value =
              (data?['lastHymnAdditionMonth'] ?? '') as String;

          if (kDebugMode) {
            print(
                'Permission updated for ${user.email}: canAddSongs = ${_canAddSongs.value}, isAdmin = ${_isAdmin.value} (DB: $isAdminDb, Super: $isSuperAdmin)');
          }
        } else {
          _canAddSongs.value = user.email == 'manassehrandriamitsiry@gmail.com';
          _isAdmin.value = user.email == 'manassehrandriamitsiry@gmail.com';
          _isSuperAdmin.value =
              user.email == 'manassehrandriamitsiry@gmail.com';
          if (kDebugMode) {
            print(
                'User document does not exist for ${user.email}. Defaulting permissions to false (unless super admin).');
          }
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error listening to user permissions: $error');
        }
        _canAddSongs.value = user.email == 'manassehrandriamitsiry@gmail.com';
        _isAdmin.value = user.email == 'manassehrandriamitsiry@gmail.com';
        _isSuperAdmin.value = user.email == 'manassehrandriamitsiry@gmail.com';
      },
    );
  }

  Future<void> signOut() async {
    try {
      await _signOutUseCase();
      _canAddSongs.value = false;
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
    }
  }

  // Method to verify user document exists and create if it doesn't
  Future<void> _verifyUserDocumentExists(String uid) async {
    try {
      if (kDebugMode) {
        print('AuthController: Verifying user document exists for UID: $uid');
      }

      final userDoc = _firestore.collection('users').doc(uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        if (kDebugMode) {
          print(
              'AuthController: User document not found, creating backup document...');
        }

        // Get current user data
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          await userDoc.set({
            'email': currentUser.email,
            'displayName': currentUser.displayName,
            'photoURL': currentUser.photoURL,
            'canAddSongs': true,
            'addedHymnsCount': 0,
            'monthlyHymnCount': 0,
            'lastHymnAdditionMonth': DateTime.now().toString().substring(0, 7),
            'emailVerified': currentUser.emailVerified,
            'isAdmin': false,
            'isSuperAdmin': false,
            'createdAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
            'uid': currentUser.uid,
          });

          if (kDebugMode) {
            print('AuthController: Backup user document created successfully');
          }
        }
      } else {
        if (kDebugMode) {
          print(
              'AuthController: User document exists, verification successful');
        }
      }
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
    }
  }

  // Public method to manually check and create user document if needed
  Future<void> ensureUserDocumentExists() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _verifyUserDocumentExists(user.uid);
    }
  }

  Future<void> updateUserPermission(String userId, bool canAddSongs) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'canAddSongs': canAddSongs,
      });
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
      rethrow;
    }
  }

  Stream<QuerySnapshot> getUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('lastLogin', descending: true)
        .snapshots();
  }

  Future<User?> signInWithGoogle() async {
    return await _signInWithGoogleUseCase();
  }
}
