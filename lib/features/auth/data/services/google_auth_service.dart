import 'package:firebase_auth/firebase_auth.dart';
import 'package:fihirana/core/utils/ui_service.dart';

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
        UIService.showAuthEmailAlreadyInUseSnackBar();
      } else {}
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
        UIService.showAuthInvalidCredentialsSnackBar();
      } else {}
    }
    return null;
  }

  bool isUserAuthenticated() {
    return FirebaseAuth.instance.currentUser != null;
  }
}
