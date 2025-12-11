import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/admin/domain/entities/admin_stats.dart';
import 'package:fihirana/features/admin/domain/entities/admin_user.dart';
import 'package:fihirana/features/admin/domain/usecases/get_admin_stats_usecase.dart';
import 'package:fihirana/features/admin/domain/usecases/stream_admin_stats_usecase.dart';
import 'package:fihirana/features/admin/domain/usecases/get_all_users_usecase.dart';
import 'package:fihirana/features/admin/domain/usecases/stream_all_users_usecase.dart';
import 'package:fihirana/features/admin/domain/usecases/update_user_admin_status_usecase.dart';
import 'package:fihirana/features/admin/domain/usecases/block_user_usecase.dart';
import 'package:fihirana/features/admin/domain/usecases/delete_user_usecase.dart';
import 'package:fihirana/features/admin/domain/usecases/get_user_deletion_stats_usecase.dart';

/// Admin controller for managing admin operations
class AdminController extends GetxController {
  final GetAdminStatsUseCase _getAdminStatsUseCase;
  final StreamAdminStatsUseCase _streamAdminStatsUseCase;
  final GetAllUsersUseCase _getAllUsersUseCase;
  final StreamAllUsersUseCase _streamAllUsersUseCase;
  final UpdateUserAdminStatusUseCase _updateUserAdminStatusUseCase;
  final BlockUserUseCase _blockUserUseCase;
  final DeleteUserUseCase _deleteUserUseCase;
  final GetUserDeletionStatsUseCase _getUserDeletionStatsUseCase;

  AdminController({
    required GetAdminStatsUseCase getAdminStatsUseCase,
    required StreamAdminStatsUseCase streamAdminStatsUseCase,
    required GetAllUsersUseCase getAllUsersUseCase,
    required StreamAllUsersUseCase streamAllUsersUseCase,
    required UpdateUserAdminStatusUseCase updateUserAdminStatusUseCase,
    required BlockUserUseCase blockUserUseCase,
    required DeleteUserUseCase deleteUserUseCase,
    required GetUserDeletionStatsUseCase getUserDeletionStatsUseCase,
  })  : _getAdminStatsUseCase = getAdminStatsUseCase,
        _streamAdminStatsUseCase = streamAdminStatsUseCase,
        _getAllUsersUseCase = getAllUsersUseCase,
        _streamAllUsersUseCase = streamAllUsersUseCase,
        _updateUserAdminStatusUseCase = updateUserAdminStatusUseCase,
        _blockUserUseCase = blockUserUseCase,
        _deleteUserUseCase = deleteUserUseCase,
        _getUserDeletionStatsUseCase = getUserDeletionStatsUseCase;

  // Observable state
  final Rx<AdminStats?> adminStats = Rx<AdminStats?>(null);
  final RxList<AdminUser> users = <AdminUser>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingUsers = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxList<AdminUser> filteredUsers = <AdminUser>[].obs;

  // Selected users for bulk operations
  final RxSet<String> selectedUserIds = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
    _setupStreams();
  }

  /// Load initial data
  Future<void> _loadInitialData() async {
    await Future.wait([
      loadAdminStats(),
      loadUsers(),
    ]);
  }

  /// Setup real-time streams
  void _setupStreams() {
    // Stream admin stats
    _streamAdminStatsUseCase.execute().listen(
      (stats) {
        adminStats.value = stats;
        if (kDebugMode) {
          print('📊 Admin stats updated: ${stats.totalUsers} users, ${stats.activeUsers} active');
        }
      },
      onError: (error) {
        errorMessage.value = 'Failed to stream admin stats: $error';
        if (kDebugMode) {
          print('❌ Error streaming admin stats: $error');
        }
      },
    );

    // Stream users
    _streamAllUsersUseCase.execute().listen(
      (userList) {
        users.assignAll(userList);
        _applyUserFilter();
        if (kDebugMode) {
          print('👥 Users updated: ${userList.length} total users');
        }
      },
      onError: (error) {
        errorMessage.value = 'Failed to stream users: $error';
        if (kDebugMode) {
          print('❌ Error streaming users: $error');
        }
      },
    );
  }

  /// Load admin statistics
  Future<void> loadAdminStats() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final stats = await _getAdminStatsUseCase.execute();
      adminStats.value = stats;
    } catch (e) {
      errorMessage.value = 'Failed to load admin stats: $e';
      if (kDebugMode) {
        print('❌ Error loading admin stats: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Load all users
  Future<void> loadUsers() async {
    try {
      isLoadingUsers.value = true;
      errorMessage.value = '';
      
      final userList = await _getAllUsersUseCase.execute();
      users.assignAll(userList);
      _applyUserFilter();
    } catch (e) {
      errorMessage.value = 'Failed to load users: $e';
      if (kDebugMode) {
        print('❌ Error loading users: $e');
      }
    } finally {
      isLoadingUsers.value = false;
    }
  }

  /// Update user admin status
  Future<bool> updateUserAdminStatus(String userId, bool isAdmin) async {
    try {
      errorMessage.value = '';
      
      final result = await _updateUserAdminStatusUseCase.execute(userId, isAdmin);
      
      if (result.success) {
        if (kDebugMode) {
          print('✅ ${result.message}');
        }
        return true;
      } else {
        errorMessage.value = result.message;
        if (kDebugMode) {
          print('❌ ${result.message}');
        }
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to update user admin status: $e';
      if (kDebugMode) {
        print('❌ Error updating user admin status: $e');
      }
      return false;
    }
  }

  /// Block or unblock user
  Future<bool> blockUser(String userId, bool isBlocked) async {
    try {
      errorMessage.value = '';
      
      final result = await _blockUserUseCase.execute(userId, isBlocked);
      
      if (result.success) {
        if (kDebugMode) {
          print('✅ ${result.message}');
        }
        return true;
      } else {
        errorMessage.value = result.message;
        if (kDebugMode) {
          print('❌ ${result.message}');
        }
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to block/unblock user: $e';
      if (kDebugMode) {
        print('❌ Error blocking/unblocking user: $e');
      }
      return false;
    }
  }

  /// Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      errorMessage.value = '';
      
      final result = await _deleteUserUseCase.execute(userId);
      
      if (result.success) {
        selectedUserIds.remove(userId);
        if (kDebugMode) {
          print('✅ ${result.message}');
        }
        return true;
      } else {
        errorMessage.value = result.message;
        if (kDebugMode) {
          print('❌ ${result.message}');
        }
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Failed to delete user: $e';
      if (kDebugMode) {
        print('❌ Error deleting user: $e');
      }
      return false;
    }
  }

  /// Get user deletion statistics
  Future<Map<String, int>?> getUserDeletionStats(String userId) async {
    try {
      return await _getUserDeletionStatsUseCase.execute(userId);
    } catch (e) {
      errorMessage.value = 'Failed to get user deletion stats: $e';
      if (kDebugMode) {
        print('❌ Error getting user deletion stats: $e');
      }
      return null;
    }
  }

  /// Search users
  void searchUsers(String query) {
    searchQuery.value = query;
    _applyUserFilter();
  }

  /// Apply search filter to users
  void _applyUserFilter() {
    if (searchQuery.value.isEmpty) {
      filteredUsers.assignAll(users);
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredUsers.assignAll(
        users.where((user) =>
          user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query)
        ).toList(),
      );
    }
  }

  /// Toggle user selection
  void toggleUserSelection(String userId) {
    if (selectedUserIds.contains(userId)) {
      selectedUserIds.remove(userId);
    } else {
      selectedUserIds.add(userId);
    }
  }

  /// Select all users
  void selectAllUsers() {
    selectedUserIds.assignAll(filteredUsers.map((user) => user.id));
  }

  /// Deselect all users
  void deselectAllUsers() {
    selectedUserIds.clear();
  }

  /// Check if user is selected
  bool isUserSelected(String userId) {
    return selectedUserIds.contains(userId);
  }

  /// Get selected users count
  int get selectedUsersCount => selectedUserIds.length;

  /// Clear error message
  void clearError() {
    errorMessage.value = '';
  }

  /// Refresh data
  @override
  Future<void> refresh() async {
    await _loadInitialData();
  }

  /// Get user by ID
  AdminUser? getUserById(String userId) {
    try {
      return users.firstWhereOrNull((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  /// Get admin users only
  List<AdminUser> get adminUsers {
    return users.where((user) => user.isAdmin).toList();
  }

  /// Get blocked users only
  List<AdminUser> get blockedUsers {
    return users.where((user) => user.isBlocked).toList();
  }

  /// Get active users (logged in within 30 days)
  List<AdminUser> get activeUsers {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return users.where((user) => 
      user.lastLogin != null && user.lastLogin!.isAfter(thirtyDaysAgo)
    ).toList();
  }

  /// Get new users (created within 30 days)
  List<AdminUser> get newUsers {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return users.where((user) => user.createdAt.isAfter(thirtyDaysAgo)).toList();
  }

  @override
  void onClose() {
    // Cleanup if needed
    super.onClose();
  }
}