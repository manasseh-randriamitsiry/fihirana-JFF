import 'package:fihirana/features/contact/domain/repositories/contact_repository.dart';
import 'package:fihirana/features/contact/domain/entities/contact.dart';
import 'package:fihirana/features/contact/data/services/contact_service.dart';

/// Repository implementation for contact operations
class ContactRepositoryImpl implements ContactRepository {
  final ContactService _contactService;

  ContactRepositoryImpl(this._contactService);

  @override
  Future<List<Contact>> getAllContacts() async {
    return await _contactService.getAllContacts();
  }

  @override
  Future<Contact?> getContactById(String id) async {
    return await _contactService.getContactById(id);
  }

  @override
  Future<bool> addContact({
    required String name,
    required String phoneNumber,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    return await _contactService.addContact(
      name: name,
      phoneNumber: phoneNumber,
      location: location,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<bool> updateContact(Contact contact) async {
    return await _contactService.updateContact(contact);
  }

  @override
  Future<bool> deleteContact(String contactId) async {
    return await _contactService.deleteContact(contactId);
  }

  @override
  Future<bool> canEditContact(Contact contact) async {
    return await _contactService.canEditContact(contact);
  }

  @override
  Stream<List<Contact>> getContactsStream() {
    return _contactService.getContactsStream();
  }

  @override
  Future<List<Contact>> searchContacts(String query) async {
    return await _contactService.searchContacts(query);
  }
}