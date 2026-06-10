import 'package:fihirana/features/admin/domain/entities/admin_stats.dart';
import 'package:fihirana/features/admin/domain/entities/admin_user.dart';
import 'package:fihirana/features/admin/domain/entities/admin_action_result.dart';

/// Admin repository interface
abstract class AdminRepository {
  /// Get admin statistics
  Future<AdminStats> getAdminStats();

  /// Stream admin statistics for real-time updates
  Stream<AdminStats> getAdminStatsStream();

  /// Get all users
  Future<List<AdminUser>> getAllUsers();

  /// Stream all users for real-time updates
  Stream<List<AdminUser>> getAllUsersStream();

  /// Update user admin status
  Future<AdminActionResult> updateUserAdminStatus(String userId, bool isAdmin);

  /// Block/unblock user
  Future<AdminActionResult> blockUser(String userId, bool isBlocked);

  /// Delete user
  Future<AdminActionResult> deleteUser(String userId);

  /// Get user by ID
  Future<AdminUser?> getUserById(String userId);

  /// Search users by query
  Future<List<AdminUser>> searchUsers(String query);

  /// Get active users count
  Future<int> getActiveUsersCount();

  /// Get new users count (last 30 days)
  Future<int> getNewUsersCount();

  /// Bulk operations on users
  Future<AdminActionResult> bulkUpdateUsers(
      List<String> userIds, Map<String, dynamic> updates);

  /// Export user data
  Future<String> exportUsersData();

  /// Get system health status
  Future<Map<String, dynamic>> getSystemHealth();

  /// Get user deletion statistics
  Future<Map<String, int>> getUserDeletionStats(String userId);
}
