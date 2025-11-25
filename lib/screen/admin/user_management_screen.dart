import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controller/color_controller.dart';
import '../../controller/auth_controller.dart';
// import './user_hymns_screen.dart'; // TODO: Implement this screen if needed
import '../../l10n/app_localizations.dart';
import '../../widgets/skeleton_user_list.dart';

class UserListWidget extends StatefulWidget {
  const UserListWidget({super.key});

  @override
  State<UserListWidget> createState() => _UserListWidgetState();
}

class _UserListWidgetState extends State<UserListWidget> {
  final ColorController colorController = Get.find<ColorController>();
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'recent';
  String _searchQuery = '';

  // Check if current user is super admin
  bool get _isSuperAdmin =>
      FirebaseAuth.instance.currentUser?.email ==
      'manassehrandriamitsiry@gmail.com';

  Stream<List<Map<String, dynamic>>> _getUsersWithHymnCount() {
    return _firestore
        .collection('users')
        .snapshots()
        .asyncMap((userSnapshot) async {
      List<Map<String, dynamic>> usersWithCount = [];

      for (var doc in userSnapshot.docs) {
        final userData = doc.data();

        final hymnCount = await _firestore
            .collection('hymns')
            .where('createdByEmail', isEqualTo: userData['email'])
            .count()
            .get();

        usersWithCount.add({
          'id': doc.id,
          ...userData,
          'hymnCount': hymnCount.count,
        });
      }

      switch (_sortBy) {
        case 'recent':
          usersWithCount.sort((a, b) => (b['lastLogin'] as Timestamp)
              .compareTo(a['lastLogin'] as Timestamp));
          break;
        case 'old':
          usersWithCount.sort((a, b) => (a['lastLogin'] as Timestamp)
              .compareTo(b['lastLogin'] as Timestamp));
          break;
        case 'songs':
          usersWithCount.sort((a, b) =>
              (b['hymnCount'] as int).compareTo(a['hymnCount'] as int));
          break;
      }

      return usersWithCount;
    });
  }

  // Generic toggle for boolean fields
  Future<void> _updateUserField(String userId, String field, bool value) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        field: value,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Toggle admin status (super admin only)
  Future<void> _toggleAdminStatus(
      String userId, String displayName, bool currentStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(currentStatus ? 'Remove Admin Access' : 'Grant Admin Access'),
        content: Text(
            'Are you sure you want to ${currentStatus ? 'remove admin access from' : 'make'} $displayName an ${currentStatus ? 'regular user' : 'admin'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(currentStatus ? 'Remove' : 'Make Admin',
                style: TextStyle(
                    color: currentStatus ? Colors.red : Colors.green)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateUserField(userId, 'isAdmin', !currentStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully ${!currentStatus ? 'granted admin access to' : 'removed admin access from'} $displayName'),
          backgroundColor: !currentStatus ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  // Disable user account (super admin only)
  Future<void> _toggleUserDisabled(
      String userId, String displayName, bool currentStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentStatus ? 'Enable User' : 'Disable User'),
        content: Text(
            'Are you sure you want to ${currentStatus ? 'enable' : 'disable'} $displayName? ${!currentStatus ? 'This will prevent them from accessing the app.' : ''}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(currentStatus ? 'Enable' : 'Disable',
                style: TextStyle(
                    color: currentStatus ? Colors.green : Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _firestore.collection('users').doc(userId).update({
        'disabled': !currentStatus,
        if (!currentStatus) 'disabledAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully ${currentStatus ? 'enabled' : 'disabled'} $displayName'),
          backgroundColor: currentStatus ? Colors.green : Colors.red,
        ),
      );
    }
  }

  // Super Admin: Delete all user data and block user permanently
  Future<void> _deleteAllUserDataAndBlock(
      String userId, String displayName, String email) async {
    final confirmationController = TextEditingController();
    bool isConfirmed = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('⚠️ PERMANENT ACTION - Delete All User Data', 
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
               content: SingleChildScrollView(
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text('This will PERMANENTLY delete ALL data for $displayName ($email):'),
                     const SizedBox(height: 12),
                     Container(
                       padding: EdgeInsets.all(8),
                       decoration: BoxDecoration(
                         color: Colors.red.withValues(alpha: 0.1),
                         borderRadius: BorderRadius.circular(8),
                         border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                       ),
                       child: Text('⚠️ This action CANNOT be undone and will affect the user experience permanently!', 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 11)),
                     ),
                     const SizedBox(height: 12),
                     TextField(
                       controller: confirmationController,
                       decoration: InputDecoration(
                         hintText: 'Type "YES" to confirm',
                         border: OutlineInputBorder(),
                         hintStyle: TextStyle(color: Colors.grey),
                       ),
                     ),
                   ],
                 ),
               ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    if (confirmationController.text == 'YES') {
                      isConfirmed = true;
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please type "YES" to confirm'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: Text('DELETE EVERYTHING', 
                             style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (!isConfirmed) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text('Deleting all user data...'),
          ],
        ),
      ),
    );

    try {
      final batch = _firestore.batch();
      
      // 1. Delete all hymns created by this user
      final hymnsSnapshot = await _firestore
          .collection('hymns')
          .where('createdByEmail', isEqualTo: email)
          .get();
      
      for (var doc in hymnsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 2. Delete all favorites for this user
      final favoritesSnapshot = await _firestore
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in favoritesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 3. Delete all history for this user
      final historySnapshot = await _firestore
          .collection('history')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in historySnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 4. Delete all recorded audio links made public by this user
      final recordingsSnapshot = await _firestore
          .collection('recordings')
          .where('uploadedBy', isEqualTo: email)
          .get();
      
      for (var doc in recordingsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 5. Delete all user recordings (local recordings that might be synced)
      final userRecordingsSnapshot = await _firestore
          .collection('user_recordings')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in userRecordingsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 6. Delete all playlist data for this user
      final playlistsSnapshot = await _firestore
          .collection('playlists')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in playlistsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 7. Delete all shared links created by this user
      final sharedLinksSnapshot = await _firestore
          .collection('shared_links')
          .where('createdBy', isEqualTo: email)
          .get();
      
      for (var doc in sharedLinksSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 8. Delete all announcements created by this user
      final announcementsSnapshot = await _firestore
          .collection('announcements')
          .where('createdBy', isEqualTo: email)
          .get();
      
      for (var doc in announcementsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 9. Delete all user settings/preferences
      final userSettingsSnapshot = await _firestore
          .collection('user_settings')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in userSettingsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 10. Remove user from any blocked_emails collection if they were added there
      final blockedEmailDoc = await _firestore
          .collection('blocked_emails')
          .doc(email.toLowerCase().trim())
          .get();
      
      if (blockedEmailDoc.exists) {
        batch.delete(blockedEmailDoc.reference);
      }

      // 11. Update user document to permanently block them
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'disabled': true,
        'permanentlyBlocked': true,
        'blockedAt': FieldValue.serverTimestamp(),
        'blockedReason': 'Super admin action - All data deleted and account permanently blocked',
        'deletedDataCount': hymnsSnapshot.docs.length,
        'deletedRecordingsCount': recordingsSnapshot.docs.length,
        'deletedUserRecordingsCount': userRecordingsSnapshot.docs.length,
        'deletedPlaylistsCount': playlistsSnapshot.docs.length,
        'deletedSharedLinksCount': sharedLinksSnapshot.docs.length,
        'deletedAnnouncementsCount': announcementsSnapshot.docs.length,
        'deletedFavoritesCount': favoritesSnapshot.docs.length,
        'deletedHistoryCount': historySnapshot.docs.length,
        'totalDeletedItems': hymnsSnapshot.docs.length + 
                           recordingsSnapshot.docs.length + 
                           userRecordingsSnapshot.docs.length + 
                           playlistsSnapshot.docs.length + 
                           sharedLinksSnapshot.docs.length + 
                           announcementsSnapshot.docs.length + 
                           favoritesSnapshot.docs.length + 
                           historySnapshot.docs.length,
      });

      // Execute all operations
      await batch.commit();

      // Close loading dialog
      Navigator.of(context).pop();

      if (!mounted) return;
      
      final totalDeleted = hymnsSnapshot.docs.length + 
                          recordingsSnapshot.docs.length + 
                          userRecordingsSnapshot.docs.length + 
                          playlistsSnapshot.docs.length + 
                          sharedLinksSnapshot.docs.length + 
                          announcementsSnapshot.docs.length + 
                          favoritesSnapshot.docs.length + 
                          historySnapshot.docs.length;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '✅ Successfully deleted $totalDeleted items for $displayName:\n'
              'User permanently blocked.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error deleting user data: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Obx(() {
      final backgroundColor = colorController.backgroundColor.value;
      final textColor = colorController.textColor.value;
      final iconColor = colorController.iconColor.value;
      final primaryColor = colorController.primaryColor.value;

      return Column(
        children: [
          // Search and Sort Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: '${l10n.userManagement}...',
                        hintStyle:
                            TextStyle(color: textColor.withValues(alpha: 0.5)),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: iconColor),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: iconColor),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.sort, color: iconColor),
                  ),
                  color: backgroundColor,
                  onSelected: (String value) {
                    setState(() {
                      _sortBy = value;
                    });
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'recent',
                      child:
                          Text(l10n.newest, style: TextStyle(color: textColor)),
                    ),
                    PopupMenuItem<String>(
                      value: 'old',
                      child:
                          Text(l10n.oldest, style: TextStyle(color: textColor)),
                    ),
                    PopupMenuItem<String>(
                      value: 'songs',
                      child: Text(l10n.sortBySongs,
                          style: TextStyle(color: textColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // User List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getUsersWithHymnCount(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '${l10n.errorOccurred}: ${snapshot.error}',
                      style: TextStyle(color: textColor),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SkeletonUserList();
                }

                final allUsers = snapshot.data ?? [];

                // Filter users based on search query and exclude super admin
                final users = allUsers.where((user) {
                  final email = (user['email'] as String? ?? '').toLowerCase();

                  // Exclude super admin
                  if (email == 'manassehrandriamitsiry@gmail.com') return false;

                  final displayName =
                      (user['displayName'] as String? ?? '').toLowerCase();
                  final query = _searchQuery.toLowerCase();
                  return email.contains(query) || displayName.contains(query);
                }).toList();

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                                size: 64,
                                color: textColor.withValues(alpha: 0.3))
                            .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true))
                            .scale(
                                duration: const Duration(seconds: 2),
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1),
                                curve: Curves.easeInOut),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noUsers,
                          style: TextStyle(
                              color: textColor.withValues(alpha: 0.7),
                              fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData = users[index];
                    final userId = userData['id'] as String;
                    final email = userData['email'] as String? ?? l10n.noEmail;
                    final displayName =
                        userData['displayName'] as String? ?? l10n.unknownUser;
                    final photoURL = userData['photoURL'] as String?;
                    final canAddSongs =
                        userData['canAddSongs'] as bool? ?? false;
                    final isAdmin = userData['isAdmin'] as bool? ?? false;
                    final isDisabled = userData['disabled'] as bool? ?? false;
                    final isPermanentlyBlocked = userData['permanentlyBlocked'] as bool? ?? false;
                    final lastLogin = userData['lastLogin'] as Timestamp?;
                    final hymnCount = userData['hymnCount'] as int? ?? 0;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      color: backgroundColor,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          // TODO: Implement UserHymnsScreen navigation
                          Get.snackbar(
                            'Coming Soon',
                            'User hymns view will be available in a future update',
                            backgroundColor: Colors.blue,
                            colorText: Colors.white,
                          );
                          // Get.to(() => UserHymnsScreen(
                          //       userId: userId,
                          //       userEmail: email,
                          //       displayName: displayName,
                          //     ));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Avatar, Name, Email
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor:
                                        primaryColor.withValues(alpha: 0.1),
                                    backgroundImage: photoURL != null
                                        ? NetworkImage(photoURL)
                                        : null,
                                    child: photoURL == null
                                        ? Text(
                                            displayName.isNotEmpty
                                                ? displayName[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                                color: primaryColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            decoration: isDisabled
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          email,
                                          style: TextStyle(
                                            color: textColor.withValues(
                                                alpha: 0.7),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isPermanentlyBlocked)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.purple.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.purple
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        '🚫 PERMANENTLY BLOCKED',
                                        style: TextStyle(
                                          color: Colors.purple,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  else if (isDisabled)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.red
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Text(
                                        'DISABLED',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Divider(color: textColor.withValues(alpha: 0.1)),
                              const SizedBox(height: 12),

                              // Stats Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatItem(
                                    icon: Icons.music_note,
                                    label: '$hymnCount Songs',
                                    color: primaryColor,
                                    textColor: textColor,
                                  ),
                                  if (lastLogin != null)
                                    _buildStatItem(
                                      icon: Icons.access_time,
                                      label: DateFormat('MMM d, y HH:mm')
                                          .format(lastLogin.toDate()),
                                      color: textColor.withValues(alpha: 0.5),
                                      textColor:
                                          textColor.withValues(alpha: 0.7),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Divider(color: textColor.withValues(alpha: 0.1)),
                              const SizedBox(height: 8),

                              // Controls Section - Fixed overflow with better layout
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // First Row: Basic Controls
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Can Add Songs Switch
                                      _buildSwitchOption(
                                        label: 'Can Add Songs',
                                        value: canAddSongs,
                                        onChanged: (val) => _updateUserField(
                                            userId, 'canAddSongs', val),
                                        activeColor: primaryColor,
                                        textColor: textColor,
                                      ),
                                      
                                      // Admin Controls (Super Admin Only)
                                      if (_isSuperAdmin) ...[
                                        _buildSwitchOption(
                                          label: 'Admin',
                                          value: isAdmin,
                                          onChanged: (val) => _toggleAdminStatus(
                                              userId, displayName, isAdmin),
                                          activeColor: Colors.orange,
                                          textColor: textColor,
                                        ),
                                      ],
                                    ],
                                  ),
                                  
                                  // Second Row: Admin Controls (Super Admin Only)
                                  if (_isSuperAdmin) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildSwitchOption(
                                          label: 'Active',
                                          value: !isDisabled,
                                          onChanged: (val) => _toggleUserDisabled(
                                              userId, displayName, isDisabled),
                                          activeColor: Colors.green,
                                          textColor: textColor,
                                          inactiveColor: Colors.red,
                                        ),
                                        
                                        // Super Admin: Delete All Data Button (only for non-permanently blocked users)
                                        if (!isPermanentlyBlocked)
                                          Flexible(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                              ),
                                              child: TextButton.icon(
                                                onPressed: () => _deleteAllUserDataAndBlock(
                                                    userId, displayName, email),
                                                icon: Icon(Icons.delete_forever, size: 14, color: Colors.red),
                                                label: Text('DELETE ALL',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    )),
                                                style: TextButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  minimumSize: Size(60, 28),
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
                  },
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchOption({
    required String label,
    required bool value,
    required Function(bool) onChanged,
    required Color activeColor,
    required Color textColor,
    Color? inactiveColor,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
            activeTrackColor: activeColor.withValues(alpha: 0.2),
            inactiveThumbColor: inactiveColor ?? Colors.grey,
            inactiveTrackColor:
                (inactiveColor ?? Colors.grey).withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}
