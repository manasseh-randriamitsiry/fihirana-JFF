import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Rx<bool> _canAddSongs = false.obs;

  bool get canAddSongs => _canAddSongs.value;

  bool get isAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email == 'manassehrandriamitsiry@gmail.com';
  }

  @override
  void onInit() {
    super.onInit();
    _initAuthListener();
    _initUserPermissions();
  }

  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _createOrUpdateUserDocument(user);
      }
    });
  }

  void _initUserPermissions() {
    final user = _auth.currentUser;
    if (user != null) {
      // Listen to user permission changes
      _firestore
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          _canAddSongs.value = snapshot.data()?['canAddSongs'] ?? false;
        }
      });
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
      Get.snackbar('Error signing out', e.toString(),
          backgroundColor: Colors.red.withOpacity(0.2),
          colorText: Colors.black,
          snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.warning_amber, color: Colors.black));
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
      Get.snackbar('Error updating user document', e.toString(),
          backgroundColor: Colors.red.withOpacity(0.2),
          colorText: Colors.black,
          snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.warning_amber, color: Colors.black));
    }
  }

  Future<void> updateUserPermission(String userId, bool canAddSongs) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'canAddSongs': canAddSongs,
      });
    } catch (e) {
      print('Error updating user permission: $e');
      Get.snackbar('Error updating user permission', e.toString(),
          backgroundColor: Colors.red.withOpacity(0.2),
          colorText: Colors.black,
          snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.warning_amber, color: Colors.black));
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
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      print('Error signing in with Google: $e');
      Get.snackbar('Error signing in with Google', e.toString(),
          backgroundColor: Colors.red.withOpacity(0.2),
          colorText: Colors.black,
          snackPosition: SnackPosition.BOTTOM,
          icon: const Icon(Icons.warning_amber, color: Colors.black));
      return null;
    }
  }
}
