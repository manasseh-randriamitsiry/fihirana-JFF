import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fihirana/features/admin/domain/entities/admin_stats.dart';
import 'package:fihirana/features/admin/domain/entities/admin_user.dart';
import 'package:fihirana/features/admin/domain/entities/admin_action_result.dart';
import 'package:fihirana/features/admin/domain/repositories/admin_repository.dart';

/// Admin repository implementation
class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore _firestore;
  static const String _usersCollection = 'users';
  static const String _statsCollection = 'stats';
  static const String _globalStatsDoc = 'global';

  AdminRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<AdminStats> getAdminStats() async {
    try {
      // Get stats document
      final statsDoc = await _firestore
          .collection(_statsCollection)
          .doc(_globalStatsDoc)
          .get();

      // Get user counts efficiently
      final totalUsersQuery = await _firestore.collection(_usersCollection).count().get();
      final totalUsers = totalUsersQuery.count ?? 0;

      // Active users count (last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final activeUsersQuery = await _firestore
          .collection(_usersCollection)
          .where('lastLogin', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .count()
          .get();
      final activeUsers = activeUsersQuery.count ?? 0;

      // Hymns count
      final hymnsSnapshot = await _firestore.collection('hymns').count().get();
      final totalHymns = hymnsSnapshot.count ?? 0;

      // Installations from stats doc
      final installations = statsDoc.data()?['installations'] as int? ?? 0;

      // Recordings count
      final recordingsQuery = await _firestore.collection('recordings').count().get();
      final totalRecordings = recordingsQuery.count ?? 0;

      // Deleted recordings count
      final deletedRecordingsQuery = await _firestore
          .collection('deleted_recordings')
          .count()
          .get();
      final deletedRecordings = deletedRecordingsQuery.count ?? 0;

      return AdminStats(
        totalUsers: totalUsers,
        activeUsers: activeUsers,
        totalHymns: totalHymns,
        installations: installations,
        totalRecordings: totalRecordings,
        deletedRecordings: deletedRecordings,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get admin stats: $e');
    }
  }

  @override
  Stream<AdminStats> getAdminStatsStream() {
    return _firestore
        .collection(_statsCollection)
        .doc(_globalStatsDoc)
        .snapshots()
        .asyncMap((_) async {
      return await getAdminStats();
    });
  }

  @override
  Future<List<AdminUser>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => _mapDocumentToAdminUser(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all users: $e');
    }
  }

  @override
  Stream<List<AdminUser>> getAllUsersStream() {
    return _firestore
        .collection(_usersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => _mapDocumentToAdminUser(doc))
          .toList();
    });
  }

  @override
  Future<AdminActionResult> updateUserAdminStatus(String userId, bool isAdmin) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'isAdmin': isAdmin,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return AdminActionResult.success(
        isAdmin ? 'User granted admin privileges' : 'Admin privileges revoked',
      );
    } catch (e) {
      return AdminActionResult.error('Failed to update user admin status: $e');
    }
  }

  @override
  Future<AdminActionResult> blockUser(String userId, bool isBlocked) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).update({
        'isBlocked': isBlocked,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return AdminActionResult.success(
        isBlocked ? 'User blocked successfully' : 'User unblocked successfully',
      );
    } catch (e) {
      return AdminActionResult.error('Failed to block/unblock user: $e');
    }
  }

  @override
  Future<AdminActionResult> deleteUser(String userId) async {
    try {
      // Use a transaction to ensure data consistency
      final batch = _firestore.batch();

      // 1. Delete user document
      final userDocRef = _firestore.collection(_usersCollection).doc(userId);
      batch.delete(userDocRef);

      // 2. Delete user's recordings
      final recordingsSnapshot = await _firestore
          .collection('recordings')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in recordingsSnapshot.docs) {
        batch.delete(doc.reference);
        
        // Also delete from deleted_recordings if it exists there
        final deletedRecordingRef = _firestore
            .collection('deleted_recordings')
            .doc(doc.id);
        batch.delete(deletedRecordingRef);
      }

      // 3. Delete user's playlists
      final playlistsSnapshot = await _firestore
          .collection('playlists')
          .where('createdBy', isEqualTo: userId)
          .get();

      for (final doc in playlistsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 4. Remove user from shared playlists (where they are a collaborator)
      final sharedPlaylistsSnapshot = await _firestore
          .collection('playlists')
          .where('collaborators', arrayContains: userId)
          .get();

      for (final doc in sharedPlaylistsSnapshot.docs) {
        batch.update(doc.reference, {
          'collaborators': FieldValue.arrayRemove([userId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 5. Delete user's favorites
      final favoritesSnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in favoritesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 6. Delete user's history
      final historySnapshot = await _firestore
          .collection('history')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in historySnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 7. Delete user's custom hymns (if any)
      final customHymnsSnapshot = await _firestore
          .collection('hymns')
          .where('createdBy', isEqualTo: userId)
          .get();

      for (final doc in customHymnsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 8. Delete user's announcements (if any)
      final announcementsSnapshot = await _firestore
          .collection('announcements')
          .where('createdBy', isEqualTo: userId)
          .get();

      for (final doc in announcementsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 9. Delete user's contacts (if any)
      final contactsSnapshot = await _firestore
          .collection('contacts')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in contactsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 10. Clean up user's settings/preferences
      final settingsDocRef = _firestore.collection('user_settings').doc(userId);
      batch.delete(settingsDocRef);

      // 11. Clean up user's notification preferences
      final notificationsDocRef = _firestore.collection('user_notifications').doc(userId);
      batch.delete(notificationsDocRef);

      // Execute the batch
      await batch.commit();

      // Log the deletion for audit purposes
      await _logUserDeletion(userId, recordingsSnapshot.docs.length,
          playlistsSnapshot.docs.length, favoritesSnapshot.docs.length);

      return AdminActionResult.success(
        'User and all associated data deleted successfully',
        data: {
          'deletedRecordings': recordingsSnapshot.docs.length,
          'deletedPlaylists': playlistsSnapshot.docs.length,
          'deletedFavorites': favoritesSnapshot.docs.length,
          'deletedHistory': historySnapshot.docs.length,
          'removedFromSharedPlaylists': sharedPlaylistsSnapshot.docs.length,
        },
      );
    } catch (e) {
      return AdminActionResult.error('Failed to delete user: $e');
    }
  }

  @override
  Future<AdminUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      
      if (!doc.exists) return null;
      
      return _mapDocumentToAdminUser(doc);
    } catch (e) {
      throw Exception('Failed to get user by ID: $e');
    }
  }

  @override
  Future<List<AdminUser>> searchUsers(String query) async {
    try {
      // Search by display name and email
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      final emailSnapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      // Combine and deduplicate results
      final allDocs = [...snapshot.docs, ...emailSnapshot.docs];
      final uniqueDocs = <String, QueryDocumentSnapshot>{};
      
      for (final doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }

      return uniqueDocs.values
          .map((doc) => _mapDocumentToAdminUser(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  @override
  Future<int> getActiveUsersCount() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final query = await _firestore
          .collection(_usersCollection)
          .where('lastLogin', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .count()
          .get();
      
      return query.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get active users count: $e');
    }
  }

  @override
  Future<int> getNewUsersCount() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final query = await _firestore
          .collection(_usersCollection)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .count()
          .get();
      
      return query.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get new users count: $e');
    }
  }

  @override
  Future<AdminActionResult> bulkUpdateUsers(
      List<String> userIds, Map<String, dynamic> updates) async {
    try {
      final batch = _firestore.batch();
      
      for (final userId in userIds) {
        final docRef = _firestore.collection(_usersCollection).doc(userId);
        batch.update(docRef, {
          ...updates,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      return AdminActionResult.success(
        'Deleted ${userIds.length} users successfully',
        data: {'deletedCount': userIds.length},
      );
    } catch (e) {
      return AdminActionResult.error('Failed to bulk update users: $e');
    }
  }

  @override
  Future<String> exportUsersData() async {
    try {
      final users = await getAllUsers();
      
      // Convert to CSV format
      final csvData = [
        'ID,Email,Display Name,Is Admin,Is Blocked,Last Login,Created At',
        ...users.map((user) => [
          user.id,
          user.email,
          user.displayName,
          user.isAdmin,
          user.isBlocked,
          user.lastLogin?.toIso8601String() ?? '',
          user.createdAt.toIso8601String(),
        ].join(',')),
      ].join('\n');

      return csvData;
    } catch (e) {
      throw Exception('Failed to export users data: $e');
    }
  }

  /// Get user deletion statistics
  @override
  Future<Map<String, int>> getUserDeletionStats(String userId) async {
    try {
      final stats = <String, int>{};

      // Count recordings
      final recordingsSnapshot = await _firestore
          .collection('recordings')
          .where('userId', isEqualTo: userId)
          .get();
      stats['recordings'] = recordingsSnapshot.docs.length;

      // Count playlists
      final playlistsSnapshot = await _firestore
          .collection('playlists')
          .where('createdBy', isEqualTo: userId)
          .get();
      stats['playlists'] = playlistsSnapshot.docs.length;

      // Count shared playlists where user is collaborator
      final sharedPlaylistsSnapshot = await _firestore
          .collection('playlists')
          .where('collaborators', arrayContains: userId)
          .get();
      stats['sharedPlaylists'] = sharedPlaylistsSnapshot.docs.length;

      // Count favorites
      final favoritesSnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();
      stats['favorites'] = favoritesSnapshot.docs.length;

      // Count history
      final historySnapshot = await _firestore
          .collection('history')
          .where('userId', isEqualTo: userId)
          .get();
      stats['history'] = historySnapshot.docs.length;

      // Count custom hymns
      final customHymnsSnapshot = await _firestore
          .collection('hymns')
          .where('createdBy', isEqualTo: userId)
          .get();
      stats['customHymns'] = customHymnsSnapshot.docs.length;

      // Count announcements
      final announcementsSnapshot = await _firestore
          .collection('announcements')
          .where('createdBy', isEqualTo: userId)
          .get();
      stats['announcements'] = announcementsSnapshot.docs.length;

      // Count contacts
      final contactsSnapshot = await _firestore
          .collection('contacts')
          .where('userId', isEqualTo: userId)
          .get();
      stats['contacts'] = contactsSnapshot.docs.length;

      return stats;
    } catch (e) {
      throw Exception('Failed to get user deletion stats: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final stats = await getAdminStats();
      final activeUsersCount = await getActiveUsersCount();
      final newUsersCount = await getNewUsersCount();

      return {
        'status': 'healthy',
        'timestamp': DateTime.now().toIso8601String(),
        'stats': stats.toMap(),
        'activeUsersCount': activeUsersCount,
        'newUsersCount': newUsersCount,
        'firestoreConnection': 'connected',
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'timestamp': DateTime.now().toIso8601String(),
        'error': e.toString(),
        'firestoreConnection': 'disconnected',
      };
    }
  }

  /// Log user deletion for audit purposes
  Future<void> _logUserDeletion(
    String userId,
    int recordingsCount,
    int playlistsCount,
    int favoritesCount,
  ) async {
    try {
      await _firestore.collection('audit_logs').add({
        'action': 'user_deletion',
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'deletedData': {
          'recordings': recordingsCount,
          'playlists': playlistsCount,
          'favorites': favoritesCount,
        },
        'performedBy': 'admin', // This could be enhanced to track which admin
      });
    } catch (e) {
      // Log error but don't fail the deletion
      if (kDebugMode) print('Failed to log user deletion: $e');
    }
  }

  /// Helper method to map Firestore document to AdminUser
  AdminUser _mapDocumentToAdminUser(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AdminUser(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      isAdmin: data['isAdmin'] ?? false,
      isBlocked: data['isBlocked'] ?? false,
      lastLogin: data['lastLogin'] != null 
          ? (data['lastLogin'] as Timestamp).toDate() 
          : null,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
}