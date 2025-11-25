import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

import '../utility/snackbar_utility.dart';
import '../services/google_drive_service.dart';
import '../services/security_service.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.file'],
  );
  final Rx<bool> _canAddSongs = false.obs;
  final Rx<bool> _isAdmin = false.obs;
  StreamSubscription<DocumentSnapshot>? _permissionSubscription;
  late final GoogleDriveService _driveService;

  bool get canAddSongs => _canAddSongs.value;
  bool get isAdmin => _isAdmin.value;
  GoogleDriveService get driveService => _driveService;

  @override
  void onInit() {
    super.onInit();

    // Initialize Google Drive service with shared GoogleSignIn instance
    _driveService = GoogleDriveService();
    _driveService.initialize(googleSignIn);

    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        _updateUserPermissions(user);

        // Ensure user document exists
        await ensureUserDocumentExists();

        // Automatically sign in to Google Drive when Firebase auth state changes
        try {
          final account = await _driveService.signIn();
          if (account != null) {
            // Check if email is banned before allowing auto sign-in
            final securityService = SecurityService.instance;
            final isEmailBanned = await securityService.isEmailBlocked(account.email);
            
            if (isEmailBanned) {
              if (kDebugMode) {
                print('🚫 Auto sign-in blocked for banned email: ${account.email}');
              }
              // Sign out immediately
              await _driveService.signOut();
            } else {
              if (kDebugMode) {
                print('✅ Auto-signed in to Google Drive for user: ${user.displayName}');
              }
            }
          }
        } catch (driveError) {
          if (kDebugMode) {
            print('⚠️ Could not auto sign-in to Google Drive: $driveError');
          }
        }
      } else {
        _permissionSubscription?.cancel();
        _permissionSubscription = null;
        _canAddSongs.value = false;
        _isAdmin.value = false;

        // Sign out from Google Drive when Firebase signs out
        try {
          await _driveService.signOut();
        } catch (e) {
          if (kDebugMode) {
            print('Error signing out from Google Drive: $e');
          }
        }
      }
    });
  }

  @override
  void onClose() {
    _permissionSubscription?.cancel();
    super.onClose();
  }

  void _updateUserPermissions(User user) {
    // Cancel existing subscription if any
    _permissionSubscription?.cancel();

    // Set up real-time listener for all users
    _permissionSubscription =
        _firestore.collection('users').doc(user.uid).snapshots().listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          _canAddSongs.value = (data?['canAddSongs'] ?? false) ||
              user.email == 'manassehrandriamitsiry@gmail.com';
          _isAdmin.value = (data?['isAdmin'] ?? false) ||
              user.email == 'manassehrandriamitsiry@gmail.com';

          if (kDebugMode) {
            print(
                'Permission updated: canAddSongs = ${_canAddSongs.value}, isAdmin = ${_isAdmin.value}');
          }
        } else {
          _canAddSongs.value = user.email == 'manassehrandriamitsiry@gmail.com';
          _isAdmin.value = user.email == 'manassehrandriamitsiry@gmail.com';
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error listening to user permissions: $error');
        }
        _canAddSongs.value = user.email == 'manassehrandriamitsiry@gmail.com';
        _isAdmin.value = user.email == 'manassehrandriamitsiry@gmail.com';
      },
    );
  }

  Future<void> signOut() async {
    try {
      await googleSignIn.signOut();
      await _auth.signOut();
      await _auth.setPersistence(Persistence.NONE);
      _canAddSongs.value = false;
    } catch (e) {
      SnackbarUtility.showError(
        title: 'Error signing out',
        message: e.toString(),
      );
    }
  }

  Future<void> _createOrUpdateUserDocument(User user) async {
    try {
      if (kDebugMode) {
        print(
            'AuthController: Creating/updating user document for ${user.email}');
        print('AuthController: User UID: ${user.uid}');
        print('AuthController: Email verified: ${user.emailVerified}');
      }

      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        if (kDebugMode) {
          print('AuthController: Creating new user document...');
        }
        await userDoc.set({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'canAddSongs': false,
          'emailVerified': user.emailVerified,
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'uid': user.uid,
        });
        if (kDebugMode) {
          print('AuthController: User document created successfully');
        }

        // Double-check that document was created
        await _verifyUserDocumentExists(user.uid);
      } else {
        if (kDebugMode) {
          print('AuthController: Updating existing user document...');
        }
        await userDoc.update({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'emailVerified': user.emailVerified,
          'lastLogin': FieldValue.serverTimestamp(),
        });
        if (kDebugMode) {
          print('AuthController: User document updated successfully');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthController: Error creating/updating user document: $e');
      }
      SnackbarUtility.showError(
        title: 'Error updating user document',
        message: e.toString(),
      );
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
            'canAddSongs': false,
            'emailVerified': currentUser.emailVerified,
            'isAdmin': false,
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
      if (kDebugMode) {
        print('AuthController: Error verifying user document: $e');
      }
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
      SnackbarUtility.showError(
        title: 'Error updating user permission',
        message: e.toString(),
      );
      rethrow;
    }
  }

  Stream<QuerySnapshot> getUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('lastLogin', descending: true)
        .snapshots();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('AuthController: Starting Google sign-in process...');
      }

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (kDebugMode) {
          print('AuthController: Google sign-in cancelled by user');
        }
        return null;
      }

      if (kDebugMode) {
        print('AuthController: Got Google user: ${googleUser.email}');
      }

      try {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        if (kDebugMode) {
          print('AuthController: Created Firebase credential, signing in...');
        }

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        if (userCredential.user != null) {
          if (kDebugMode) {
            print(
                'AuthController: Firebase sign-in successful, creating user document...');
          }
          await _createOrUpdateUserDocument(userCredential.user!);
        } else {
          if (kDebugMode) {
            print('AuthController: Firebase sign-in failed - user is null');
          }
        }

        return userCredential;
      } catch (e) {
        if (kDebugMode) {
          print('AuthController: Firebase sign-in error: $e');
        }
        if (_auth.currentUser != null) {
          if (kDebugMode) {
            print('AuthController: User already signed in, returning null');
          }
          return null;
        }
        rethrow;
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthController: Google sign-in error: $e');
        SnackbarUtility.showError(
          title: 'Error signing in',
          message: e.toString(),
        );
      }
      return null;
    }
  }
}
