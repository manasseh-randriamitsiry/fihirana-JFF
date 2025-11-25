import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

import '../utility/snackbar_utility.dart';
import '../services/google_drive_service.dart';

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
        
        // Automatically sign in to Google Drive when Firebase auth state changes
        try {
          await _driveService.signIn();
          if (kDebugMode) {
            print('✅ Auto-signed in to Google Drive for user: ${user.displayName}');
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

    // Admin check (hardcoded email)
    if (user.email == 'manassehrandriamitsiry@gmail.com') {
      _isAdmin.value = true;
      _canAddSongs.value = true;
      return;
    }

    // Set up real-time listener for regular users
    _permissionSubscription =
        _firestore.collection('users').doc(user.uid).snapshots().listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          _canAddSongs.value = data?['canAddSongs'] ?? false;
          if (kDebugMode) {
            print('Permission updated: canAddSongs = ${_canAddSongs.value}');
          }
        } else {
          _canAddSongs.value = false;
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error listening to user permissions: $error');
        }
        _canAddSongs.value = false;
      },
    );
  }

  Future<void> refreshPermissions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _updateUserPermissions(user);
    }
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
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'canAddSongs': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        await userDoc.update({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      SnackbarUtility.showError(
        title: 'Error updating user document',
        message: e.toString(),
      );
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
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      try {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        if (userCredential.user != null) {
          await _createOrUpdateUserDocument(userCredential.user!);
        }

        return userCredential;
      } catch (e) {
        if (_auth.currentUser != null) {
          return null;
        }
        rethrow;
      }
    } catch (e) {
      if (kDebugMode) {
        SnackbarUtility.showError(
          title: 'Error signing in',
          message: e.toString(),
        );
      }
      return null;
    }
  }
}
