import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:fihirana/features/auth/domain/entities/user.dart';
import 'package:fihirana/features/auth/domain/repositories/auth_repository.dart';
import 'package:fihirana/features/auth/data/services/google_auth_service.dart';
import 'package:fihirana/features/recording/data/services/google_drive_service.dart';
import 'package:fihirana/core/security/security_service.dart';
import 'package:fihirana/core/utils/snackbar_utility.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthService _authService;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final SecurityService _securityService;
  late final GoogleDriveService _driveService;

  AuthRepositoryImpl(
    this._authService,
    this._firestore,
    this._googleSignIn,
    this._securityService,
  ) {
    _driveService = Get.find<GoogleDriveService>();
    _driveService.initialize(_googleSignIn);
  }

  @override
  Future<User?> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        print('AuthRepository: Starting Google sign-in process...');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (kDebugMode) {
          print('AuthRepository: Google sign-in cancelled by user');
        }
        return null;
      }

      if (kDebugMode) {
        print('AuthRepository: Got Google user: ${googleUser.email}');
      }

      // Check if email is banned before proceeding
      final emailBanned = await isEmailBanned(googleUser.email);
      if (emailBanned) {

        if (kDebugMode) {
          print('AuthRepository: Banned email detected: ${googleUser.email}');
        }
        await _googleSignIn.signOut();
        return null;
      }

      try {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final firebase_auth.OAuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final firebase_auth.UserCredential userCredential = await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);

        if (userCredential.user != null) {
          final user = _mapFirebaseUserToEntity(userCredential.user!);
          await createOrUpdateUserDocument(user);
          
          // Auto sign in to Google Drive
          try {
            final account = await _driveService.signIn();
            if (account != null) {
              if (kDebugMode) {
                print('AuthRepository: Auto-signed in to Google Drive');
              }
            }
          } catch (driveError) {
            if (kDebugMode) {
              print('AuthRepository: Could not auto sign-in to Google Drive: $driveError');
            }
          }
          
          return user;
        }
      } catch (e) {
        if (kDebugMode) {
          print('AuthRepository: Firebase sign-in error: $e');
        }
        rethrow;
      }
    } catch (e) {
      final errorMessage = e.toString();
      // Check for the specific PigeonUserDetails cast error which is a known issue in the plugin
      // and should not be displayed to the user as it might be a silent failure or regression
      final isPigeonError = errorMessage.contains("subtype of type 'PigeonUserDetails?'");
      
      if (kDebugMode || isPigeonError) {
        print('AuthRepository: Google sign-in error: $e');
      }
      
      // Only show snackbar if it's NOT the ignored error
      if (!isPigeonError) {
        SnackbarUtility.showError(
          title: 'Error signing in',
          message: errorMessage,
        );
      }
    }
    return null;
  }

  @override
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    final firebaseUser = await _authService.signUpWithEmailAndPassword(email, password);
    if (firebaseUser != null) {
      final user = _mapFirebaseUserToEntity(firebaseUser);
      await createOrUpdateUserDocument(user);
      return user;
    }
    return null;
  }

  @override
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    final firebaseUser = await _authService.signInWithEmailAndPassword(email, password);
    if (firebaseUser != null) {
      final user = _mapFirebaseUserToEntity(firebaseUser);
      await createOrUpdateUserDocument(user);
      return user;
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await firebase_auth.FirebaseAuth.instance.signOut();
      await firebase_auth.FirebaseAuth.instance.setPersistence(firebase_auth.Persistence.NONE);
    } catch (e) {
      SnackbarUtility.showError(
        title: 'Error signing out',
        message: e.toString(),
      );
    }
  }

  @override
  Future<void> createOrUpdateUserDocument(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.id);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set(user.toFirestore());
      } else {
        await userDoc.update({
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'emailVerified': user.emailVerified,
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthRepository: Error creating/updating user document: $e');
      }
      SnackbarUtility.showError(
        title: 'Error updating user document',
        message: e.toString(),
      );
    }
  }

  @override
  Future<void> ensureUserDocumentExists() async {
    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await createOrUpdateUserDocument(_mapFirebaseUserToEntity(currentUser));
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        return User.fromFirebaseUser(userDoc.data()!, firebaseUser.uid);
      }
    }
    return null;
  }

  @override
  Stream<User?> get authStateChanges {
    return firebase_auth.FirebaseAuth.instance.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser != null) {
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (userDoc.exists) {
          return User.fromFirebaseUser(userDoc.data()!, firebaseUser.uid);
        }
      }
      return null;
    });
  }

  @override
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

  @override
  Future<bool> isEmailBanned(String email) async {
    return await _securityService.isEmailBlocked(email);
  }

  @override
  Stream<User> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => User.fromFirebaseUser(snapshot.data()!, userId));
  }

  @override
  Stream<QuerySnapshot> getUsersStream() {
    return _firestore
        .collection('users')
        .orderBy('lastLogin', descending: true)
        .snapshots();
  }

  @override
  bool get isUserAuthenticated => _authService.isUserAuthenticated();

  @override
  User? get currentUser {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    return firebaseUser != null ? _mapFirebaseUserToEntity(firebaseUser) : null;
  }

  User _mapFirebaseUserToEntity(firebase_auth.User user) {
    return User(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      emailVerified: user.emailVerified,
      createdAt: DateTime.now(), // Will be updated from Firestore
      lastLogin: DateTime.now(), // Will be updated from Firestore
    );
  }
}