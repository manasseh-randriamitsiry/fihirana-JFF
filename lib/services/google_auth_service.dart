import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        Get.snackbar('The email address is already in use.',
            'Try another email address.',
            backgroundColor: Colors.red.withOpacity(0.2),
            colorText: Colors.black,
            icon: const Icon(Icons.warning_amber, color: Colors.black));
      } else {
      }
    }
    return null;
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        Get.snackbar('The email address is already in use.',
            'Try another email address.',
            backgroundColor: Colors.red.withOpacity(0.2),
            colorText: Colors.black,
            icon: const Icon(Icons.warning_amber, color: Colors.black));
      } else {
      }
    }
    return null;
  }

  bool isUserAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }
}