import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../utility/snackbar_utility.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Rx<bool> _canAddSongs = false.obs;
  final Rx<bool> _isAdmin = false.obs;

  bool get canAddSongs => _canAddSongs.value;
  bool get isAdmin => _isAdmin.value;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _updateUserPermissions(user);
      } else {
        _canAddSongs.value = false;
        _isAdmin.value = false;
      }
    });
  }

  Future<void> _updateUserPermissions(User user) async {
    // Check if user is admin
    if (user.email == 'manassehrandriamitsiry@gmail.com') {
      _isAdmin.value = true;
      _canAddSongs.value = true;
      return;
    }

    // Check user permissions in Firestore
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      _canAddSongs.value = userDoc.exists && (userDoc.data()?['canAddSongs'] ?? false);
    } catch (e) {
      print('Error updating permissions: $e');
      _canAddSongs.value = false;
    }
  }

  // Call this method after login or when permissions might have changed
  Future<void> refreshPermissions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _updateUserPermissions(user);
    }
  }

  Future<void> signOut() async {
    try {
      // Sign out from Google
      await _googleSignIn.signOut();
      // Sign out from Firebase
      await _auth.signOut();
      // Clear any persisted auth state
      await _auth.setPersistence(Persistence.NONE);
      // Reset local state
      _canAddSongs.value = false;
    } catch (e) {
      print('Error signing out: $e');
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
        // Create new user document
        await userDoc.set({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'canAddSongs': false,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing user document
        await userDoc.update({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error creating/updating user document: $e');
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
      print('Error updating user permission: $e');
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
      // Start the sign-in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      try {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Try to sign in with Firebase
        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        return userCredential;
      } catch (e) {
        print('Error during Firebase sign-in: $e');
        // Even if there's an error with Firebase, try to continue with the Google account
        if (_auth.currentUser != null) {
          return null; // Return null but don't block the sign-in
        }
        rethrow;
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      // Don't show error to user in release mode
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
