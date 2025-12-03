import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fihirana/models/hymn.dart';
import 'package:fihirana/utility/snackbar_utility.dart';
import 'package:fihirana/controller/auth_controller.dart';

class FirebaseHymnService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final AuthController _authController;

  FirebaseHymnService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required AuthController authController,
  })  : _auth = auth,
        _firestore = firestore,
        _authController = authController;

  Stream<List<Hymn>> getFirebaseHymnsStream() {
    return _firestore.collection('hymns').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Hymn.fromJson(data, doc.id);
      }).toList();
    });
  }

  Future<Hymn?> getHymnByIdFromFirebase(String hymnId) async {
    try {
      final doc = await _firestore.collection('hymns').doc(hymnId).get();
      if (doc.exists) {
        return Hymn.fromJson(doc.data()!, doc.id);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<DateTime> _getServerTime() async {
    try {
      final response = await http.head(Uri.parse('https://www.google.com'));
      if (response.headers['date'] != null) {
        return HttpDate.parse(response.headers['date']!);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  Future<bool> _checkUserLimit(User user) async {
    // Get server time to prevent local time manipulation
    final now = await _getServerTime();
    final currentMonth = now.toString().substring(0, 7); // Format: YYYY-MM

    // Get current user data to check limit
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data();

    if (userData != null) {
      final lastMonth = userData['lastHymnAdditionMonth'] as String? ?? '';
      final monthlyCount = userData['monthlyHymnCount'] as int? ?? 0;
      final isAdmin = userData['isAdmin'] as bool? ?? false;

      // Check limit if not admin
      if (!isAdmin) {
        if (lastMonth == currentMonth && monthlyCount >= 5) {
          SnackbarUtility.showError(
            title: 'Fetra tratra',
            message:
                'Efa feno ny fetra 5 hira isam-bolana. Miandrasa volana manaraka.',
          );
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _updateUserStats(User user, String currentMonth, String lastMonth) async {
    // Prepare update data
    final Map<String, dynamic> updateData = {
      'addedHymnsCount': FieldValue.increment(1),
    };

    if (lastMonth != currentMonth) {
      // New month, reset counter
      updateData['monthlyHymnCount'] = 1;
      updateData['lastHymnAdditionMonth'] = currentMonth;
    } else {
      // Same month, increment counter
      updateData['monthlyHymnCount'] = FieldValue.increment(1);
    }

    await _firestore.collection('users').doc(user.uid).update(updateData);
  }

  Future<bool> addHymn(Hymn hymn) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        SnackbarUtility.showError(
          title: 'Tsy misy fifandraisan-tsara',
          message: 'Mila miditra aloha ianao mba hahafahana manampy hira',
        );
        return false;
      }

      if (!await _checkUserLimit(user)) {
        return false;
      }

      hymn.createdBy = user.displayName ?? user.email ?? 'Unknown User';
      hymn.createdByEmail = user.email;

      final docRef = await _firestore.collection('hymns').add(hymn.toMap());

      hymn.id = docRef.id;
      await docRef.update({'id': docRef.id});

      // Get server time again? Wait, for stats, need currentMonth.
      final now = await _getServerTime();
      final currentMonth = now.toString().substring(0, 7);

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final lastMonth = userData?['lastHymnAdditionMonth'] as String? ?? '';

      await _updateUserStats(user, currentMonth, lastMonth);

      SnackbarUtility.showSuccess(
        title: 'Vita soa aman-tsara',
        message: 'Voapetraha soa aman-tsara ny hira',
      );

      return true;
    } catch (e) {
      SnackbarUtility.showError(
        title: 'Nisy olana',
        message: 'Tsy afaka napetraka ny hira: $e',
      );
      return false;
    }
  }

  Future<void> updateHymn(String hymnId, Hymn hymn) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        SnackbarUtility.showError(
          title: 'Tsy misy fifandraisan-tsara',
          message: 'Mila miditra aloha ianao mba hahafahana manova hira',
        );
        return;
      }

      await _firestore.collection('hymns').doc(hymnId).update(hymn.toMap());

      SnackbarUtility.showSuccess(
        title: 'Vita soa aman-tsara',
        message: 'Nohavaozina soa aman-tsara ny hira',
      );
    } catch (e) {
      SnackbarUtility.showError(
        title: 'Nisy olana',
        message: 'Tsy afaka novaozina ny hira: $e',
      );
    }
  }

  Future<void> deleteHymn(String hymnId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        SnackbarUtility.showError(
          title: 'Tsy misy fifandraisan-tsara',
          message: 'Mila miditra aloha ianao mba hahafahana mamafa hira',
        );
        return;
      }

      // Get the hymn to check ownership
      final hymnDoc = await _firestore.collection('hymns').doc(hymnId).get();
      if (!hymnDoc.exists) {
        SnackbarUtility.showError(
          title: 'Hira ts hita',
          message: 'Tsy hita ilay hira tianao hamafa',
        );
        return;
      }

      final data = hymnDoc.data();
      if (data == null) {
        SnackbarUtility.showError(
          title: 'Nisy olana',
          message: 'Tsy afaka voafafa ny hira: Data ts hita',
        );
        return;
      }

      final hymn = Hymn.fromJson(data, hymnId);

      // Check if user is admin/superAdmin or owns the hymn
      if (!_authController.isAdmin &&
          !_authController.isSuperAdmin &&
          hymn.createdByEmail != user.email) {
        SnackbarUtility.showError(
          title: 'Tsy manana alalana',
          message:
              'Tsy afaka mamafa io hira io afa-tsy ilay namorona azy na mpandrindra',
        );
        return;
      }

      await _firestore.collection('hymns').doc(hymnId).delete();

      SnackbarUtility.showSuccess(
        title: 'Vita soa aman-tsara',
        message: 'Voafafa soa aman-tsara ny hira',
      );
    } catch (e) {
      SnackbarUtility.showError(
        title: 'Nisy olana',
        message: 'Tsy afaka voafafa ny hira: $e',
      );
    }
  }
}