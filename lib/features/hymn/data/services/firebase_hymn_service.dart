import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fihirana/features/hymn/domain/entities/hymn.dart';

class FirebaseHymnService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  FirebaseHymnService({
    required this.auth,
    required this.firestore,
  });

  /// Streams all additional hymns from Firebase
  Stream<List<Hymn>> getFirebaseHymnsStream() {
    try {
      return firestore.collection('hymns').snapshots().map((snapshot) {
        final hymns = snapshot.docs.map((doc) {
          try {
            final data = doc.data();
            return Hymn.fromJson(data, doc.id);
          } catch (e) {
            if (kDebugMode) {
              print('Error parsing hymn ${doc.id}: $e');
            }
            return null;
          }
        }).where((hymn) => hymn != null).cast<Hymn>().toList();
        
        if (kDebugMode) {
          print('🎵 FirebaseHymnService: Loaded ${hymns.length} hymns from Firebase');
        }
        return hymns;
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error streaming Firebase hymns: $e');
      }
      return Stream.value([]);
    }
  }

  /// Fetches a single hymn by ID from Firebase
  Future<Hymn?> getHymnByIdFromFirebase(String hymnId) async {
    try {
      final doc = await firestore.collection('hymns').doc(hymnId).get();
      
      if (!doc.exists) {
        if (kDebugMode) {
          print('⚠️ Hymn $hymnId not found in Firebase');
        }
        return null;
      }
      
      final data = doc.data();
      if (data == null) {
        if (kDebugMode) {
          print('⚠️ Hymn $hymnId has no data');
        }
        return null;
      }
      
      return Hymn.fromJson(data, doc.id);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error fetching hymn $hymnId: $e');
      }
      return null;
    }
  }

  /// Adds a new hymn to Firebase
  Future<bool> addHymn(Hymn hymn) async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('❌ Cannot add hymn: User not authenticated');
        }
        return false;
      }

      // Generate a unique ID for the hymn
      final docRef = firestore.collection('hymns').doc();
      
      // Create hymn with user metadata
      final hymnWithMetadata = Hymn(
        id: docRef.id,
        hymnNumber: hymn.hymnNumber,
        title: hymn.title,
        verses: hymn.verses,
        bridge: hymn.bridge,
        hymnHint: hymn.hymnHint,
        createdAt: DateTime.now(),
        createdBy: user.displayName ?? 'Unknown',
        createdByEmail: user.email ?? '',
      );

      // Save to Firestore
      await docRef.set(hymnWithMetadata.toMap());
      
      if (kDebugMode) {
        print('✅ Successfully added hymn ${hymn.hymnNumber}: ${hymn.title}');
      }
      
      // Update user's hymn count for monthly tracking
      await _updateUserHymnCount(user.uid);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error adding hymn: $e');
      }
      return false;
    }
  }

  /// Updates an existing hymn in Firebase
  Future<void> updateHymn(String hymnId, Hymn hymn) async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('❌ Cannot update hymn: User not authenticated');
        }
        return;
      }

      // Check if hymn exists
      final doc = await firestore.collection('hymns').doc(hymnId).get();
      if (!doc.exists) {
        if (kDebugMode) {
          print('⚠️ Cannot update: Hymn $hymnId not found');
        }
        return;
      }

      // Preserve original creation metadata
      final existingData = doc.data() ?? {};
      final updatedHymn = hymn.toMap();
      
      // Keep original creation info
      updatedHymn['createdAt'] = existingData['createdAt'];
      updatedHymn['createdBy'] = existingData['createdBy'];
      updatedHymn['createdByEmail'] = existingData['createdByEmail'];
      
      // Add update metadata
      updatedHymn['updatedAt'] = Timestamp.fromDate(DateTime.now());
      updatedHymn['updatedBy'] = user.displayName ?? 'Unknown';
      updatedHymn['updatedByEmail'] = user.email ?? '';

      await firestore.collection('hymns').doc(hymnId).update(updatedHymn);
      
      if (kDebugMode) {
        print('✅ Successfully updated hymn $hymnId: ${hymn.title}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating hymn $hymnId: $e');
      }
      rethrow;
    }
  }

  /// Deletes a hymn from Firebase
  Future<void> deleteHymn(String hymnId) async {
    try {
      final user = auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('❌ Cannot delete hymn: User not authenticated');
        }
        return;
      }

      // Check if hymn exists and verify permissions
      final doc = await firestore.collection('hymns').doc(hymnId).get();
      if (!doc.exists) {
        if (kDebugMode) {
          print('⚠️ Cannot delete: Hymn $hymnId not found');
        }
        return;
      }

      final data = doc.data();
      final createdByEmail = data?['createdByEmail'] as String?;
      
      // Check if user is authorized (creator or admin)
      final isCreator = createdByEmail == user.email;
      final isAdmin = await _isUserAdmin(user.uid);
      
      if (!isCreator && !isAdmin) {
        if (kDebugMode) {
          print('❌ Permission denied: User ${user.email} cannot delete hymn $hymnId');
        }
        throw Exception('You do not have permission to delete this hymn');
      }

      await firestore.collection('hymns').doc(hymnId).delete();
      
      if (kDebugMode) {
        print('✅ Successfully deleted hymn $hymnId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting hymn $hymnId: $e');
      }
      rethrow;
    }
  }

  /// Helper method to update user's monthly hymn count
  Future<void> _updateUserHymnCount(String userId) async {
    try {
      final userDoc = firestore.collection('users').doc(userId);
      final now = DateTime.now();
      final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        
        if (snapshot.exists) {
          final data = snapshot.data() ?? {};
          final lastMonth = data['lastHymnMonth'] as String?;
          int count = (data['hymnsThisMonth'] as int?) ?? 0;
          
          // Reset count if it's a new month
          if (lastMonth != currentMonth) {
            count = 0;
          }
          
          transaction.update(userDoc, {
            'hymnsThisMonth': count + 1,
            'lastHymnMonth': currentMonth,
          });
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error updating user hymn count: $e');
      }
      // Don't throw - this is non-critical
    }
  }

  /// Helper method to check if user is an admin
  Future<bool> _isUserAdmin(String userId) async {
    try {
      final userDoc = await firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      
      final data = userDoc.data();
      return (data?['isAdmin'] == true) || (data?['isSuperAdmin'] == true);
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error checking admin status: $e');
      }
      return false;
    }
  }
}