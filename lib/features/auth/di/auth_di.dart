import 'package:get/get.dart';
import 'package:fihirana/features/auth/domain/repositories/auth_repository.dart';
import 'package:fihirana/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fihirana/features/auth/data/services/google_auth_service.dart';
import 'package:fihirana/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:fihirana/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:fihirana/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:fihirana/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:fihirana/features/auth/domain/usecases/ensure_user_document_exists_usecase.dart';
import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';

/// Auth dependency injection configuration
class AuthDI {
  /// Initialize auth dependencies
  static void init() {
    // Service
    Get.lazyPut<FirebaseAuthService>(
      () => FirebaseAuthService(),
    );

    // Repository
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(
        Get.find<FirebaseAuthService>(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
    );

    // Use cases
    Get.lazyPut<SignInWithGoogleUseCase>(
      () => SignInWithGoogleUseCase(Get.find<AuthRepository>()),
    );

    Get.lazyPut<SignUpUseCase>(
      () => SignUpUseCase(Get.find<AuthRepository>()),
    );

    Get.lazyPut<SignInUseCase>(
      () => SignInUseCase(Get.find<AuthRepository>()),
    );

    Get.lazyPut<SignOutUseCase>(
      () => SignOutUseCase(Get.find<AuthRepository>()),
    );

    Get.lazyPut<EnsureUserDocumentExistsUseCase>(
      () => EnsureUserDocumentExistsUseCase(Get.find<AuthRepository>()),
    );

    // Controller
    Get.lazyPut<AuthController>(
      () => AuthController(
        signInWithGoogleUseCase: Get.find<SignInWithGoogleUseCase>(),
        signOutUseCase: Get.find<SignOutUseCase>(),
        ensureUserDocumentExistsUseCase: Get.find<EnsureUserDocumentExistsUseCase>(),
      ),
    );
  }
}