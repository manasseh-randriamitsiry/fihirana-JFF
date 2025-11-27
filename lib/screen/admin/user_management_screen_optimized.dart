import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../controller/color_controller.dart';

class OptimizedUserManagementScreen extends StatefulWidget {
  const OptimizedUserManagementScreen({super.key});

  @override
  State<OptimizedUserManagementScreen> createState() =>
      _OptimizedUserManagementScreenState();
}

class _OptimizedUserManagementScreenState
    extends State<OptimizedUserManagementScreen>
    with AutomaticKeepAliveClientMixin {
  final ColorController _colorController = Get.find<ColorController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'recent';
  String _searchQuery = '';

  // Virtual scrolling and pagination
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 25; // Smaller page size for better performance
  List<DocumentSnapshot> _lastDocuments = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final List<Map<String, dynamic>> _users = [];
  final Map<String, int> _hymnCountCache = {};

  // Debounced search
  Timer? _searchTimer;

  // Performance optimization flags
  bool _isSuperAdmin = false;
  bool _disposed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkSuperAdminStatus();

    _loadUsers();

    _searchController.addListener(() {
      _searchTimer?.cancel();
      _searchTimer = Timer(const Duration(milliseconds: 300), () {
        _performSearch(_searchController.text);
      });
    });

    _scrollController.addListener(_onScroll);
  }

  Future<void> _checkSuperAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          final data = doc.data();
          _isSuperAdmin = (data != null && data['isSuperAdmin'] == true) ||
              user.email == 'manassehrandriamitsiry@gmail.com';
        });
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollController.dispose();
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_isLoadingMore &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        _hasMore) {
      _loadUsers();
    }
  }

  // Optimized user loading with minimal data fetching
  Future<void> _loadUsers({bool refresh = false}) async {
    if (_disposed) return;

    if (refresh) {
      _lastDocuments.clear();
      _users.clear();
      _hasMore = true;
      _hymnCountCache.clear();
    }

    if (!_hasMore || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      Query query = _firestore
          .collection('users')
          .orderBy(_getSortField(), descending: _getSortDescending())
          .limit(_pageSize);

      // Apply search filter server-side if searching
      if (_searchQuery.isNotEmpty) {
        if (_searchQuery.contains('@')) {
          query = query
              .where('email',
                  isGreaterThanOrEqualTo: _searchQuery.toLowerCase())
              .where('email',
                  isLessThanOrEqualTo: '${_searchQuery.toLowerCase()}\uf8ff');
        } else {
          query = query
              .where('displayName', isGreaterThanOrEqualTo: _searchQuery)
              .where('displayName', isLessThanOrEqualTo: '$_searchQuery\uf8ff');
        }
      }

      if (_lastDocuments.isNotEmpty) {
        query = query.startAfterDocument(_lastDocuments.last);
      }

      final snapshot = await query.get();

      final newUsers = snapshot.docs.map((doc) {
        final userData = doc.data() as Map<String, dynamic>?;
        return <String, dynamic>{
          'id': doc.id,
          if (userData != null) ...userData,
          'hymnCount': 0, // Will be loaded on demand
        };
      }).toList();

      if (!_disposed) {
        setState(() {
          _users.addAll(newUsers);
          _lastDocuments = snapshot.docs;
          _hasMore = snapshot.docs.length == _pageSize;
          _isLoadingMore = false;
        });
      }

      // Preload hymn counts for first few users only
      _preloadHymnCounts(newUsers.take(3).toList());
    } catch (e) {
      if (!_disposed) {
        setState(() => _isLoadingMore = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error loading users: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Debounced search implementation
  Future<void> _performSearch(String query) async {
    if (_disposed) return;

    final newQuery = query.trim();
    if (newQuery != _searchQuery) {
      setState(() => _searchQuery = newQuery);
      _loadUsers(refresh: true);
    }
  }

  // Optimized hymn count preloading
  Future<void> _preloadHymnCounts(List<Map<String, dynamic>> users) async {
    for (final user in users) {
      final email = user['email'] as String?;
      if (email != null && !_hymnCountCache.containsKey(email)) {
        try {
          final count = await _firestore
              .collection('hymns')
              .where('createdByEmail', isEqualTo: email)
              .count()
              .get();
          _hymnCountCache[email] = count.count ?? 0;
        } catch (e) {
          _hymnCountCache[email] = 0;
        }
      }
    }
  }

  // Get hymn count with caching
  Future<int> _getHymnCount(String email) async {
    if (_hymnCountCache.containsKey(email)) {
      return _hymnCountCache[email]!;
    }

    await _preloadHymnCounts([
      {'email': email}
    ]);
    return _hymnCountCache[email] ?? 0;
  }

  String _getSortField() {
    switch (_sortBy) {
      case 'recent':
      case 'old':
        return 'lastLogin';
      case 'created':
        return 'createdAt';
      case 'name':
        return 'displayName';
      default:
        return 'lastLogin';
    }
  }

  bool _getSortDescending() {
    switch (_sortBy) {
      case 'recent':
      case 'created':
        return true;
      case 'old':
      case 'name':
        return false;
      default:
        return true;
    }
  }

  // Optimized user field update
  Future<void> _updateUserField(String userId, String field, bool value) async {
    try {
      await _firestore.collection('users').doc(userId).update({field: value});

      // Update local state immediately for better UX
      final userIndex = _users.indexWhere((u) => u['id'] == userId);
      if (userIndex != -1) {
        setState(() {
          _users[userIndex][field] = value;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error updating user: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // Toggle admin status (super admin only)
  Future<void> _toggleAdminStatus(
      String userId, String displayName, bool currentStatus) async {
    final confirmed = await _showConfirmationDialog(
      title: currentStatus ? 'Remove Admin Access' : 'Grant Admin Access',
      content:
          'Are you sure you want to ${currentStatus ? 'remove admin access from' : 'make'} $displayName an ${currentStatus ? 'regular user' : 'admin'}?',
      confirmText: currentStatus ? 'Remove' : 'Make Admin',
      confirmColor: currentStatus ? Colors.red : Colors.green,
    );

    if (confirmed == true) {
      await _updateUserField(userId, 'isAdmin', !currentStatus);
      if (mounted) {
        _showSuccessSnackBar(
            'Successfully ${!currentStatus ? 'granted admin access to' : 'removed admin access from'} $displayName');
      }
    }
  }

  // Toggle user disabled status
  Future<void> _toggleUserDisabled(
      String userId, String displayName, bool currentStatus) async {
    final confirmed = await _showConfirmationDialog(
      title: currentStatus ? 'Enable User' : 'Disable User',
      content:
          'Are you sure you want to ${currentStatus ? 'enable' : 'disable'} $displayName? ${!currentStatus ? 'This will prevent them from accessing app.' : ''}',
      confirmText: currentStatus ? 'Enable' : 'Disable',
      confirmColor: currentStatus ? Colors.green : Colors.red,
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'disabled': !currentStatus,
          if (!currentStatus) 'disabledAt': FieldValue.serverTimestamp(),
        });

        // Update local state
        final userIndex = _users.indexWhere((u) => u['id'] == userId);
        if (userIndex != -1) {
          setState(() {
            _users[userIndex]['disabled'] = !currentStatus;
          });
        }

        if (mounted) {
          _showSuccessSnackBar(
              'Successfully ${currentStatus ? 'enabled' : 'disabled'} $displayName');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error updating user: $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // Toggle super admin status
  Future<void> _toggleSuperAdminStatus(
      String userId, String displayName, bool currentStatus) async {
    final confirmed = await _showConfirmationDialog(
      title: currentStatus ? 'Remove Super Admin' : 'Make Super Admin',
      content:
          'Are you sure you want to ${currentStatus ? 'remove super admin access from' : 'make'} $displayName a ${currentStatus ? 'regular admin' : 'SUPER ADMIN'}?\n\n⚠️ Super Admins have full control over the system!',
      confirmText: currentStatus ? 'Remove' : 'Make Super Admin',
      confirmColor: currentStatus ? Colors.red : Colors.purple,
    );

    if (confirmed == true) {
      // If making super admin, ensure they are also regular admin
      if (!currentStatus) {
        await _updateUserField(userId, 'isAdmin', true);
      }

      await _updateUserField(userId, 'isSuperAdmin', !currentStatus);

      // Update local state
      final userIndex = _users.indexWhere((u) => u['id'] == userId);
      if (userIndex != -1) {
        setState(() {
          _users[userIndex]['isSuperAdmin'] = !currentStatus;
          if (!currentStatus) _users[userIndex]['isAdmin'] = true;
        });
      }

      if (mounted) {
        _showSuccessSnackBar(
            'Successfully ${!currentStatus ? 'granted super admin access to' : 'removed super admin access from'} $displayName');
      }
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText, style: TextStyle(color: confirmColor)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
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
              title: const Text('⚠️ PERMANENT ACTION - Delete All User Data',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'This will PERMANENTLY delete ALL data for $displayName ($email):'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                          '⚠️ This action CANNOT be undone and will affect user experience permanently!',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 11)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmationController,
                      decoration: const InputDecoration(
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
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    if (confirmationController.text == 'YES') {
                      setState(() => isConfirmed = true);
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please type "YES" to confirm'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: const Text('DELETE EVERYTHING',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (!isConfirmed) return;

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
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
        'blockedReason':
            'Super admin action - All data deleted and account permanently blocked',
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
      if (mounted) {
        Navigator.of(context).pop();
      }

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

      // Refresh user list to show updated status
      _loadUsers(refresh: true);
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

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

  // Ultra-compact user card for performance
  Widget _buildUltraCompactUserCard(
    Map<String, dynamic> userData,
    Color textColor,
    Color primaryColor,
    Color backgroundColor,
  ) {
    final userId = userData['id'] as String;
    final email = userData['email'] as String? ?? 'No Email';
    final displayName = userData['displayName'] as String? ?? 'Unknown User';
    final photoURL = userData['photoURL'] as String?;
    final canAddSongs = userData['canAddSongs'] as bool? ?? false;
    final isAdmin = userData['isAdmin'] as bool? ?? false;
    final isDisabled = userData['disabled'] as bool? ?? false;
    final isPermanentlyBlocked =
        userData['permanentlyBlocked'] as bool? ?? false;
    final isSuperAdminUser = userData['isSuperAdmin'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            // Optional: Show user details on tap
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Ultra-compact avatar
                CircleAvatar(
                  radius: 16,
                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                  backgroundImage:
                      photoURL != null ? NetworkImage(photoURL) : null,
                  child: photoURL == null
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          decoration:
                              isDisabled ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Status indicators and controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status badges
                    if (isPermanentlyBlocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('🚫', style: TextStyle(fontSize: 8)),
                      )
                    else if (isDisabled)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('⛔', style: TextStyle(fontSize: 8)),
                      ),

                    // Hymn count (minimal)
                    FutureBuilder<int>(
                      future: _getHymnCount(email),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count == 0) return const SizedBox.shrink();
                        return Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),

                    // Compact controls
                    const SizedBox(width: 8),
                    _buildMiniSwitch(
                      value: canAddSongs,
                      onChanged: (val) =>
                          _updateUserField(userId, 'canAddSongs', val),
                      activeColor: primaryColor,
                    ),

                    if (_isSuperAdmin) ...[
                      const SizedBox(width: 4),
                      _buildMiniSwitch(
                        value: isAdmin,
                        onChanged: (val) =>
                            _toggleAdminStatus(userId, displayName, isAdmin),
                        activeColor: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      _buildMiniSwitch(
                        value: isSuperAdminUser,
                        onChanged: (val) => _toggleSuperAdminStatus(
                            userId, displayName, isSuperAdminUser),
                        activeColor: Colors.purple,
                      ),
                      const SizedBox(width: 4),
                      _buildMiniSwitch(
                        value: !isDisabled,
                        onChanged: (val) => _toggleUserDisabled(
                            userId, displayName, isDisabled),
                        activeColor: Colors.green,
                        inactiveColor: Colors.red,
                      ),
                      if (!isPermanentlyBlocked) ...[
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _deleteAllUserDataAndBlock(
                              userId, displayName, email),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(
                              Icons.delete_forever,
                              size: 14,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 150)).slideX(
        begin: -0.05, end: 0, duration: const Duration(milliseconds: 150));
  }

  // Ultra-compact switch widget
  Widget _buildMiniSwitch({
    required bool value,
    required Function(bool) onChanged,
    required Color activeColor,
    Color? inactiveColor,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 40,
        height: 24,
        decoration: BoxDecoration(
          color: value
              ? activeColor.withValues(alpha: 0.3)
              : (inactiveColor ?? Colors.grey).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? activeColor
                : (inactiveColor ?? Colors.grey).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: value ? activeColor : (inactiveColor ?? Colors.grey),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      final backgroundColor = _colorController.backgroundColor.value;
      final textColor = _colorController.textColor.value;
      final iconColor = _colorController.iconColor.value;
      final primaryColor = _colorController.primaryColor.value;

      return Column(
        children: [
          // Optimized search and sort header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border(
                  bottom: BorderSide(color: textColor.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search users...',
                        hintStyle: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 14),
                        border: InputBorder.none,
                        prefixIcon:
                            Icon(Icons.search, color: iconColor, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: iconColor, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.sort, color: iconColor, size: 20),
                    color: backgroundColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onSelected: (String value) {
                      setState(() {
                        _sortBy = value;
                      });
                      _loadUsers(refresh: true);
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem<String>(
                        value: 'recent',
                        child: Text('Recent',
                            style: TextStyle(color: textColor, fontSize: 14)),
                      ),
                      PopupMenuItem<String>(
                        value: 'old',
                        child: Text('Oldest',
                            style: TextStyle(color: textColor, fontSize: 14)),
                      ),
                      PopupMenuItem<String>(
                        value: 'name',
                        child: Text('Name',
                            style: TextStyle(color: textColor, fontSize: 14)),
                      ),
                      PopupMenuItem<String>(
                        value: 'created',
                        child: Text('Created',
                            style: TextStyle(color: textColor, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User count and loading indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  _searchQuery.isEmpty
                      ? 'Loaded: ${_users.length}${_hasMore ? '+' : ''} users'
                      : 'Found: ${_users.length}${_hasMore ? '+' : ''} users',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (_isLoadingMore)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                if (_hasMore && !_isLoadingMore)
                  Text(
                    'Scroll for more',
                    style: TextStyle(
                      color: primaryColor.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),

          // Virtual scrolling list
          Expanded(
            child: _users.isEmpty && _isLoadingMore
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : _users.isEmpty
                    ? Center(
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
                                    end: const Offset(1.1, 1.1)),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No users found'
                                  : 'No users match "$_searchQuery"',
                              style: TextStyle(
                                  color: textColor.withValues(alpha: 0.7),
                                  fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _users.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _users.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final userData = _users[index];
                          return _buildUltraCompactUserCard(userData, textColor,
                              primaryColor, backgroundColor);
                        },
                      ),
          ),
        ],
      );
    });
  }
}
