import 'package:get/get.dart';
import 'package:fihirana/features/contact/domain/repositories/contact_repository.dart';
import 'package:fihirana/features/contact/data/repositories/contact_repository_impl.dart';
import 'package:fihirana/features/contact/data/services/contact_service.dart';
import 'package:fihirana/features/contact/domain/usecases/get_all_contacts_usecase.dart';
import 'package:fihirana/features/contact/domain/usecases/add_contact_usecase.dart';
import 'package:fihirana/features/contact/domain/usecases/update_contact_usecase.dart';
import 'package:fihirana/features/contact/domain/usecases/delete_contact_usecase.dart';
import 'package:fihirana/features/contact/domain/usecases/can_edit_contact_usecase.dart';
import 'package:fihirana/features/contact/domain/usecases/stream_contacts_usecase.dart';
import 'package:fihirana/features/contact/domain/usecases/search_contacts_usecase.dart';
import 'package:fihirana/features/contact/presentation/controllers/contact_controller.dart';

/// Dependency injection for contact feature
class ContactDI {
  static const String _contactRepositoryTag = 'contactRepository';
  static const String _contactControllerTag = 'contactController';

  /// Initialize contact dependencies
  static void initialize() {
    // Service
    Get.lazyPut<ContactService>(
      () => ContactService(),
    );

    // Repository
    Get.lazyPut<ContactRepository>(
      () => ContactRepositoryImpl(
        Get.find<ContactService>(),
      ),
      tag: _contactRepositoryTag,
    );

    // Use cases
    Get.lazyPut<GetAllContactsUseCase>(
      () => GetAllContactsUseCase(
        Get.find<ContactRepository>(tag: _contactRepositoryTag),
      ),
    );

    Get.lazyPut<AddContactUseCase>(
      () => AddContactUseCase(
        Get.find<ContactRepository>(tag: _contactRepositoryTag),
      ),
    );

    Get.lazyPut<UpdateContactUseCase>(
      () => UpdateContactUseCase(
        Get.find<ContactRepository>(tag: _contactRepositoryTag),
      ),
    );

    Get.lazyPut<DeleteContactUseCase>(
      () => DeleteContactUseCase(
        Get.find<ContactRepository>(tag: _contactRepositoryTag),
      ),
    );

    Get.lazyPut<CanEditContactUseCase>(
      () => CanEditContactUseCase(
        Get.find<ContactRepository>(tag: _contactRepositoryTag),
      ),
    );

    Get.lazyPut<StreamContactsUseCase>(
      () => StreamContactsUseCase(
        Get.find<ContactRepository>(tag: _contactRepositoryTag),
      ),
    );

    Get.lazyPut<SearchContactsUseCase>(
      () => SearchContactsUseCase(
        Get.find<ContactRepository>(tag: _contactRepositoryTag),
      ),
    );

    // Controller
    Get.lazyPut<ContactController>(
      () => ContactController(
        getAllContactsUseCase: Get.find<GetAllContactsUseCase>(),
        addContactUseCase: Get.find<AddContactUseCase>(),
        updateContactUseCase: Get.find<UpdateContactUseCase>(),
        deleteContactUseCase: Get.find<DeleteContactUseCase>(),
        canEditContactUseCase: Get.find<CanEditContactUseCase>(),
        streamContactsUseCase: Get.find<StreamContactsUseCase>(),
        searchContactsUseCase: Get.find<SearchContactsUseCase>(),
      ),
      tag: _contactControllerTag,
    );
  }

  /// Get contact controller
  static ContactController get contactController {
    return Get.find<ContactController>(tag: _contactControllerTag);
  }

  /// Get contact repository
  static ContactRepository get contactRepository {
    return Get.find<ContactRepository>(tag: _contactRepositoryTag);
  }

  /// Dispose contact dependencies
  static void dispose() {
    Get.delete<ContactController>(tag: _contactControllerTag);
    Get.delete<SearchContactsUseCase>();
    Get.delete<StreamContactsUseCase>();
    Get.delete<CanEditContactUseCase>();
    Get.delete<DeleteContactUseCase>();
    Get.delete<UpdateContactUseCase>();
    Get.delete<AddContactUseCase>();
    Get.delete<GetAllContactsUseCase>();
    Get.delete<ContactRepository>(tag: _contactRepositoryTag);
    Get.delete<ContactService>();
  }

  /// Reset contact dependencies (for testing)
  static void reset() {
    dispose();
    initialize();
  }
}