import 'package:fihirana/features/contact/domain/entities/contact.dart';

/// Repository interface for contact operations
abstract class ContactRepository {
  /// Get all contacts
  Future<List<Contact>> getAllContacts();

  /// Get contact by ID
  Future<Contact?> getContactById(String id);

  /// Add new contact
  Future<bool> addContact({
    required String name,
    required String phoneNumber,
    String? location,
    double? latitude,
    double? longitude,
  });

  /// Update existing contact
  Future<bool> updateContact(Contact contact);

  /// Delete contact
  Future<bool> deleteContact(String contactId);

  /// Check if user can edit contact
  Future<bool> canEditContact(Contact contact);

  /// Get contacts stream
  Stream<List<Contact>> getContactsStream();

  /// Search contacts
  Future<List<Contact>> searchContacts(String query);
}
