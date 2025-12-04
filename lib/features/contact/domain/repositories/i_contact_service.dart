import 'package:fihirana/features/contact/domain/entities/contact.dart';

abstract class IContactService {
  Stream<List<Contact>> getContactsStream();
  Future<bool> addContact({
    required String name,
    required String phoneNumber,
    String? location,
    double? latitude,
    double? longitude,
  });
  Future<bool> updateContact(Contact contact);
  Future<bool> deleteContact(String contactId);
  Future<bool> canEditContact(Contact contact);
  Future<List<Contact>> getAllContacts();
  Future<Contact?> getContactById(String id);
  Future<List<Contact>> searchContacts(String query);
}