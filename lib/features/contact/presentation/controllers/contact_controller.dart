import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as flutter_contacts;
import 'package:fihirana/features/contact/domain/entities/contact.dart';
import 'package:fihirana/features/contact/domain/usecases/get_all_contacts_usecase.dart';
import 'package:fihirana/features/contact/domain/usecases/add_contact_usecase.dart';
import 'package:fihirana/features/contact/domain/usecases/update_contact_usecase.dart';
import 'package:fihirana/features/contact/domain/usecases/delete_contact_usecase.dart';
import 'package:fihirana/features/contact/domain/usecases/can_edit_contact_usecase.dart';
import 'package:fihirana/features/contact/domain/usecases/stream_contacts_usecase.dart';
import 'package:fihirana/features/contact/domain/usecases/search_contacts_usecase.dart';
import 'package:fihirana/features/contact/data/services/contact_import_service.dart';
import 'package:fihirana/core/error/error_handler.dart';

/// Contact controller for managing contact operations
class ContactController extends GetxController {
  // ignore: unused_field
  final GetAllContactsUseCase _getAllContactsUseCase;
  final AddContactUseCase _addContactUseCase;
  final UpdateContactUseCase _updateContactUseCase;
  final DeleteContactUseCase _deleteContactUseCase;
  final CanEditContactUseCase _canEditContactUseCase;
  final StreamContactsUseCase _streamContactsUseCase;
  // ignore: unused_field
  final SearchContactsUseCase _searchContactsUseCase;

  ContactController({
    required GetAllContactsUseCase getAllContactsUseCase,
    required AddContactUseCase addContactUseCase,
    required UpdateContactUseCase updateContactUseCase,
    required DeleteContactUseCase deleteContactUseCase,
    required CanEditContactUseCase canEditContactUseCase,
    required StreamContactsUseCase streamContactsUseCase,
    required SearchContactsUseCase searchContactsUseCase,
  })  : _getAllContactsUseCase = getAllContactsUseCase,
        _addContactUseCase = addContactUseCase,
        _updateContactUseCase = updateContactUseCase,
        _deleteContactUseCase = deleteContactUseCase,
        _canEditContactUseCase = canEditContactUseCase,
        _streamContactsUseCase = streamContactsUseCase,
        _searchContactsUseCase = searchContactsUseCase;

  // Observable state
  final RxList<Contact> contacts = <Contact>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxList<Contact> filteredContacts = <Contact>[].obs;

  @override
  void onInit() {
    super.onInit();
    _setupStreams();
  }

  /// Setup streams
  void _setupStreams() {
    _streamContactsUseCase.execute().listen(
      (contactList) {
        contacts.assignAll(contactList);
        _applySearchFilter();
        if (kDebugMode) {
          print('📞 Contacts updated: ${contactList.length} total');
        }
      },
      onError: (error) {
        errorMessage.value = 'Failed to stream contacts: $error';
        if (kDebugMode) {
          print('❌ Error streaming contacts: $error');
        }
      },
    );
  }

  /// Search contacts
  void searchContacts(String query) {
    searchQuery.value = query;
    _applySearchFilter();
  }

  /// Apply search filter
  void _applySearchFilter() {
    if (searchQuery.value.isEmpty) {
      filteredContacts.assignAll(contacts);
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredContacts.assignAll(
        contacts
            .where((contact) =>
                contact.name.toLowerCase().contains(query) ||
                contact.phoneNumber.contains(query) ||
                (contact.location?.toLowerCase().contains(query) ?? false))
            .toList(),
      );
    }
  }

  /// Add contact
  Future<bool> addContact({
    required String name,
    required String phoneNumber,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      errorMessage.value = '';
      isLoading.value = true;

      final success = await _addContactUseCase.execute(
        name: name,
        phoneNumber: phoneNumber,
        location: location,
        latitude: latitude,
        longitude: longitude,
      );

      if (success) {
        if (kDebugMode) {
          print('✅ Contact added successfully');
        }
      } else {
        errorMessage.value = 'Failed to add contact';
      }

      return success;
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update contact
  Future<bool> updateContact(Contact contact) async {
    try {
      errorMessage.value = '';
      isLoading.value = true;

      final success = await _updateContactUseCase.execute(contact);

      if (success) {
        if (kDebugMode) {
          print('✅ Contact updated successfully');
        }
      } else {
        errorMessage.value = 'Failed to update contact';
      }

      return success;
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete contact
  Future<bool> deleteContact(String contactId) async {
    try {
      errorMessage.value = '';
      isLoading.value = true;

      final success = await _deleteContactUseCase.execute(contactId);

      if (success) {
        if (kDebugMode) {
          print('✅ Contact deleted successfully');
        }
      } else {
        errorMessage.value = 'Failed to delete contact';
      }

      return success;
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Check if can edit contact
  Future<bool> canEditContact(Contact contact) async {
    return await _canEditContactUseCase.execute(contact);
  }

  /// Import contacts
  Future<List<flutter_contacts.Contact>?> importContacts() async {
    try {
      return await ContactImportService.importContacts(Get.context!);
    } catch (e) {
      ErrorHandler.handleError(e, message: 'errorOccurred'.tr);
      return null;
    }
  }

  /// Clear error
  void clearError() {
    errorMessage.value = '';
  }

  /// Refresh data
  @override
  Future<void> refresh() async {
    // Reload stream
    _setupStreams();
  }

  @override
  void onClose() {
    // Cleanup if needed
    super.onClose();
  }
}
