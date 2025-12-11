import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fihirana/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:fihirana/features/admin/domain/repositories/admin_repository.dart';
import 'package:fihirana/features/admin/domain/usecases/get_admin_stats_usecase.dart';
import 'package:fihirana/features/admin/domain/usecases/stream_admin_stats_usecase.dart';
import 'package:fihirana/features/admin/domain/usecases/get_all_users_usecase.dart';
import 'package:fihirana/features/admin/domain/usecases/stream_all_users_usecase.dart';
import 'package:fihirana/features/admin/domain/usecases/update_user_admin_status_usecase.dart';
import 'package:fihirana/features/admin/domain/usecases/block_user_usecase.dart';
import 'package:fihirana/features/admin/domain/usecases/delete_user_usecase.dart';
import 'package:fihirana/features/admin/domain/usecases/get_user_deletion_stats_usecase.dart';
import 'package:fihirana/features/admin/presentation/controllers/admin_controller.dart';

/// Dependency injection for admin feature
class AdminDI {
  static const String _adminRepositoryTag = 'adminRepository';
  static const String _adminControllerTag = 'adminController';

  /// Initialize admin dependencies
  static void initialize() {
    // Repository
    Get.lazyPut<AdminRepository>(
      () => AdminRepositoryImpl(
        firestore: FirebaseFirestore.instance,
      ),
      tag: _adminRepositoryTag,
    );

    // Use cases
    Get.lazyPut<GetAdminStatsUseCase>(
      () => GetAdminStatsUseCase(
        Get.find<AdminRepository>(tag: _adminRepositoryTag),
      ),
    );

    Get.lazyPut<StreamAdminStatsUseCase>(
      () => StreamAdminStatsUseCase(
        Get.find<AdminRepository>(tag: _adminRepositoryTag),
      ),
    );

    Get.lazyPut<GetAllUsersUseCase>(
      () => GetAllUsersUseCase(
        Get.find<AdminRepository>(tag: _adminRepositoryTag),
      ),
    );

    Get.lazyPut<StreamAllUsersUseCase>(
      () => StreamAllUsersUseCase(
        Get.find<AdminRepository>(tag: _adminRepositoryTag),
      ),
    );

    Get.lazyPut<UpdateUserAdminStatusUseCase>(
      () => UpdateUserAdminStatusUseCase(
        Get.find<AdminRepository>(tag: _adminRepositoryTag),
      ),
    );

    Get.lazyPut<BlockUserUseCase>(
      () => BlockUserUseCase(
        Get.find<AdminRepository>(tag: _adminRepositoryTag),
      ),
    );

    Get.lazyPut<DeleteUserUseCase>(
      () => DeleteUserUseCase(
        Get.find<AdminRepository>(tag: _adminRepositoryTag),
      ),
    );

    Get.lazyPut<GetUserDeletionStatsUseCase>(
      () => GetUserDeletionStatsUseCase(
        Get.find<AdminRepository>(tag: _adminRepositoryTag),
      ),
    );

    // Controller
    Get.lazyPut<AdminController>(
      () => AdminController(
        getAdminStatsUseCase: Get.find<GetAdminStatsUseCase>(),
        streamAdminStatsUseCase: Get.find<StreamAdminStatsUseCase>(),
        getAllUsersUseCase: Get.find<GetAllUsersUseCase>(),
        streamAllUsersUseCase: Get.find<StreamAllUsersUseCase>(),
        updateUserAdminStatusUseCase: Get.find<UpdateUserAdminStatusUseCase>(),
        blockUserUseCase: Get.find<BlockUserUseCase>(),
        deleteUserUseCase: Get.find<DeleteUserUseCase>(),
        getUserDeletionStatsUseCase: Get.find<GetUserDeletionStatsUseCase>(),
      ),
      tag: _adminControllerTag,
    );
  }

  /// Get admin controller
  static AdminController get adminController {
    return Get.find<AdminController>(tag: _adminControllerTag);
  }

  /// Get admin repository
  static AdminRepository get adminRepository {
    return Get.find<AdminRepository>(tag: _adminRepositoryTag);
  }

  /// Dispose admin dependencies
  static void dispose() {
    Get.delete<AdminController>(tag: _adminControllerTag);
    Get.delete<DeleteUserUseCase>();
    Get.delete<BlockUserUseCase>();
    Get.delete<UpdateUserAdminStatusUseCase>();
    Get.delete<StreamAllUsersUseCase>();
    Get.delete<GetAllUsersUseCase>();
    Get.delete<StreamAdminStatsUseCase>();
    Get.delete<GetAdminStatsUseCase>();
    Get.delete<AdminRepository>(tag: _adminRepositoryTag);
  }

  /// Reset admin dependencies (for testing)
  static void reset() {
    dispose();
    initialize();
  }
}