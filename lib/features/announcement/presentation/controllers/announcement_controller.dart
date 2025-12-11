import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fihirana/features/announcement/domain/entities/announcement.dart';
import 'package:fihirana/features/announcement/domain/usecases/create_announcement_usecase.dart';
import 'package:fihirana/features/announcement/domain/usecases/update_announcement_usecase.dart';
import 'package:fihirana/features/announcement/domain/usecases/delete_announcement_usecase.dart';
import 'package:fihirana/features/announcement/domain/usecases/get_all_announcements_usecase.dart';
import 'package:fihirana/features/announcement/domain/usecases/get_active_announcements_usecase.dart';
import 'package:fihirana/features/announcement/domain/usecases/stream_all_announcements_usecase.dart';
import 'package:fihirana/features/announcement/domain/usecases/stream_active_announcements_usecase.dart';
import 'package:fihirana/features/announcement/domain/usecases/check_new_announcements_usecase.dart';
import 'package:fihirana/features/announcement/domain/usecases/clear_seen_announcements_usecase.dart';
import 'package:fihirana/core/error/error_handler.dart';

/// Announcement controller for managing announcement operations
class AnnouncementController extends GetxController {
  final CreateAnnouncementUseCase _createAnnouncementUseCase;
  final UpdateAnnouncementUseCase _updateAnnouncementUseCase;
  final DeleteAnnouncementUseCase _deleteAnnouncementUseCase;
  final GetAllAnnouncementsUseCase _getAllAnnouncementsUseCase;
  final GetActiveAnnouncementsUseCase _getActiveAnnouncementsUseCase;
  final StreamAllAnnouncementsUseCase _streamAllAnnouncementsUseCase;
  final StreamActiveAnnouncementsUseCase _streamActiveAnnouncementsUseCase;
  final CheckNewAnnouncementsUseCase _checkNewAnnouncementsUseCase;
  final ClearSeenAnnouncementsUseCase _clearSeenAnnouncementsUseCase;
  final FirebaseAuth _auth;

  AnnouncementController({
    required CreateAnnouncementUseCase createAnnouncementUseCase,
    required UpdateAnnouncementUseCase updateAnnouncementUseCase,
    required DeleteAnnouncementUseCase deleteAnnouncementUseCase,
    required GetAllAnnouncementsUseCase getAllAnnouncementsUseCase,
    required GetActiveAnnouncementsUseCase getActiveAnnouncementsUseCase,
    required StreamAllAnnouncementsUseCase streamAllAnnouncementsUseCase,
    required StreamActiveAnnouncementsUseCase streamActiveAnnouncementsUseCase,
    required CheckNewAnnouncementsUseCase checkNewAnnouncementsUseCase,
    required ClearSeenAnnouncementsUseCase clearSeenAnnouncementsUseCase,
    required FirebaseAuth auth,
  })  : _createAnnouncementUseCase = createAnnouncementUseCase,
        _updateAnnouncementUseCase = updateAnnouncementUseCase,
        _deleteAnnouncementUseCase = deleteAnnouncementUseCase,
        _getAllAnnouncementsUseCase = getAllAnnouncementsUseCase,
        _getActiveAnnouncementsUseCase = getActiveAnnouncementsUseCase,
        _streamAllAnnouncementsUseCase = streamAllAnnouncementsUseCase,
        _streamActiveAnnouncementsUseCase = streamActiveAnnouncementsUseCase,
        _checkNewAnnouncementsUseCase = checkNewAnnouncementsUseCase,
        _clearSeenAnnouncementsUseCase = clearSeenAnnouncementsUseCase,
        _auth = auth;

  // Observable state
  final RxList<Announcement> announcements = <Announcement>[].obs;
  final RxList<Announcement> activeAnnouncements = <Announcement>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingActive = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxList<Announcement> filteredAnnouncements = <Announcement>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
    _setupStreams();
  }

  /// Load initial data
  Future<void> _loadInitialData() async {
    await Future.wait([
      loadAllAnnouncements(),
      loadActiveAnnouncements(),
    ]);
  }

  /// Setup real-time streams
  void _setupStreams() {
    // Stream all announcements
    _streamAllAnnouncementsUseCase.execute().listen(
      (announcementList) {
        announcements.assignAll(announcementList);
        _applySearchFilter();
        if (kDebugMode) {
          print('📢 Announcements updated: ${announcementList.length} total');
        }
      },
      onError: (error) {
        errorMessage.value = 'Failed to stream announcements: $error';
        if (kDebugMode) {
          print('❌ Error streaming announcements: $error');
        }
      },
    );

    // Stream active announcements
    _streamActiveAnnouncementsUseCase.execute().listen(
      (activeList) {
        activeAnnouncements.assignAll(activeList);
        if (kDebugMode) {
          print('✅ Active announcements updated: ${activeList.length} active');
        }
      },
      onError: (error) {
        errorMessage.value = 'Failed to stream active announcements: $error';
        if (kDebugMode) {
          print('❌ Error streaming active announcements: $error');
        }
      },
    );
  }

  /// Load all announcements
  Future<void> loadAllAnnouncements() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final announcementList = await _getAllAnnouncementsUseCase.execute();
      announcements.assignAll(announcementList);
      _applySearchFilter();
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  /// Load active announcements
  Future<void> loadActiveAnnouncements() async {
    try {
      isLoadingActive.value = true;
      errorMessage.value = '';
      
      final activeList = await _getActiveAnnouncementsUseCase.execute();
      activeAnnouncements.assignAll(activeList);
    } catch (e) {
      errorMessage.value = 'Failed to load active announcements: $e';
      if (kDebugMode) {
        print('❌ Error loading active announcements: $e');
      }
    } finally {
      isLoadingActive.value = false;
    }
  }

  /// Create a new announcement
  Future<bool> createAnnouncement({
    required String title,
    required String message,
    DateTime? expiresAt,
  }) async {
    try {
      errorMessage.value = '';
      isLoading.value = true;

      final user = _auth.currentUser;
      if (user == null) {
        errorMessage.value = 'User not authenticated';
        return false;
      }

      await _createAnnouncementUseCase.execute(
        title: title,
        message: message,
        expiresAt: expiresAt,
        createdBy: user.displayName ?? 'Admin',
        createdByEmail: user.email ?? '',
      );

      if (kDebugMode) {
        print('✅ Announcement created successfully');
      }
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to create announcement: $e';
      if (kDebugMode) {
        print('❌ Error creating announcement: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update an existing announcement
  Future<bool> updateAnnouncement({
    required String id,
    required String title,
    required String message,
    DateTime? expiresAt,
  }) async {
    try {
      errorMessage.value = '';
      isLoading.value = true;

      await _updateAnnouncementUseCase.execute(
        id: id,
        title: title,
        message: message,
        expiresAt: expiresAt,
      );

      if (kDebugMode) {
        print('✅ Announcement updated successfully');
      }
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to update announcement: $e';
      if (kDebugMode) {
        print('❌ Error updating announcement: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete an announcement
  Future<bool> deleteAnnouncement(String id) async {
    try {
      errorMessage.value = '';
      isLoading.value = true;

      await _deleteAnnouncementUseCase.execute(id);

      if (kDebugMode) {
        print('✅ Announcement deleted successfully');
      }
      return true;
    } catch (e) {
      errorMessage.value = 'Failed to delete announcement: $e';
      if (kDebugMode) {
        print('❌ Error deleting announcement: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Check for new announcements
  Future<void> checkNewAnnouncements() async {
    try {
      await _checkNewAnnouncementsUseCase.execute();
      if (kDebugMode) {
        print('🔔 New announcements check completed');
      }
    } catch (e) {
      errorMessage.value = 'Failed to check new announcements: $e';
      if (kDebugMode) {
        print('❌ Error checking new announcements: $e');
      }
    }
  }

  /// Clear seen announcements
  Future<void> clearSeenAnnouncements() async {
    try {
      await _clearSeenAnnouncementsUseCase.execute();
      await checkNewAnnouncements(); // Re-check after clearing
      if (kDebugMode) {
        print('🧹 Seen announcements cleared');
      }
    } catch (e) {
      errorMessage.value = 'Failed to clear seen announcements: $e';
      if (kDebugMode) {
        print('❌ Error clearing seen announcements: $e');
      }
    }
  }

  /// Search announcements
  void searchAnnouncements(String query) {
    searchQuery.value = query;
    _applySearchFilter();
  }

  /// Apply search filter to announcements
  void _applySearchFilter() {
    if (searchQuery.value.isEmpty) {
      filteredAnnouncements.assignAll(announcements);
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredAnnouncements.assignAll(
        announcements.where((announcement) =>
          announcement.title.toLowerCase().contains(query) ||
          announcement.message.toLowerCase().contains(query)
        ).toList(),
      );
    }
  }

  /// Check if current user is admin
  bool get isAdmin {
    final user = _auth.currentUser;
    return user?.email == 'manassehrandriamitsiry@gmail.com';
  }

  /// Get announcement by ID
  Announcement? getAnnouncementById(String id) {
    try {
      return announcements.firstWhereOrNull((announcement) => announcement.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get expired announcements
  List<Announcement> get expiredAnnouncements {
    return announcements.where((announcement) => announcement.isExpired()).toList();
  }

  /// Get announcements expiring soon (within 7 days)
  List<Announcement> get announcementsExpiringSoon {
    final sevenDaysFromNow = DateTime.now().add(const Duration(days: 7));
    return announcements.where((announcement) =>
        announcement.expiresAt != null &&
        announcement.expiresAt!.isBefore(sevenDaysFromNow) &&
        announcement.expiresAt!.isAfter(DateTime.now())
    ).toList();
  }

  /// Get announcements count
  int get announcementsCount => announcements.length;

  /// Get active announcements count
  int get activeAnnouncementsCount => activeAnnouncements.length;

  /// Get expired announcements count
  int get expiredAnnouncementsCount => expiredAnnouncements.length;

  /// Clear error message
  void clearError() {
    errorMessage.value = '';
  }

  /// Refresh data
  @override
  Future<void> refresh() async {
    await _loadInitialData();
  }

  @override
  void onClose() {
    // Cleanup if needed
    super.onClose();
  }
}