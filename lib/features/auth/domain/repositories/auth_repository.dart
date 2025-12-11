import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fihirana/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  // Authentication methods
  Future<User?> signInWithGoogle();
  Future<User?> signUpWithEmailAndPassword(String email, String password);
  Future<User?> signInWithEmailAndPassword(String email, String password);
  Future<void> signOut();

  // User management
  Future<void> createOrUpdateUserDocument(User user);
  Future<void> ensureUserDocumentExists();
  Future<User?> getCurrentUser();
  Stream<User?> get authStateChanges;

  // User permissions
  Future<void> updateUserPermission(String userId, bool canAddSongs);
  Future<bool> isEmailBanned(String email);

  // User data streams
  Stream<User> getUserStream(String userId);
  Stream<QuerySnapshot> getUsersStream();

  // User state
  bool get isUserAuthenticated;
  User? get currentUser;
}