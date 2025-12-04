import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:fihirana/features/contact/domain/entities/contact.dart';
import 'package:fihirana/features/auth/presentation/controllers/auth_controller.dart';

class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthController _authController = Get.find<AuthController>();

  // Get all contacts stream
  Stream<List<Contact>> getContactsStream() {
    return _firestore
        .collection('contacts')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Contact.fromJson(data);
      }).toList();
    });
  }

  // Add a new contact
  Future<bool> addContact({
    required String name,
    required String phoneNumber,
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final now = DateTime.now();
      final displayName = user.displayName ?? user.email ?? 'Anonymous';

      final contactData = {
        'name': name,
        'phoneNumber': phoneNumber,
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'userId': user.uid,
        'userName': displayName,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      await _firestore.collection('contacts').add(contactData);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding contact: $e');
      }
      return false;
    }
  }

  // Update a contact
  Future<bool> updateContact(Contact contact) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check permission
      if (!await canEditContact(contact)) return false;

      final now = DateTime.now();

      await _firestore.collection('contacts').doc(contact.id).update({
        'name': contact.name,
        'phoneNumber': contact.phoneNumber,
        'location': contact.location,
        'latitude': contact.latitude,
        'longitude': contact.longitude,
        'updatedAt': now.toIso8601String(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating contact: $e');
      }
      return false;
    }
  }

  // Delete a contact
  Future<bool> deleteContact(String contactId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final contactDoc =
          await _firestore.collection('contacts').doc(contactId).get();
      if (!contactDoc.exists) return false;

      final data = contactDoc.data();
      if (data == null) return false;

      data['id'] = contactDoc.id;
      final contact = Contact.fromJson(data);

      // Check permission
      if (!await canEditContact(contact)) return false;

      await _firestore.collection('contacts').doc(contactId).delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting contact: $e');
      }
      return false;
    }
  }

  // Check if current user can edit a contact (owns it or is admin)
  Future<bool> canEditContact(Contact contact) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // Admins can edit all contacts
    if (_authController.isAdmin) {
      return true;
    }

    // Users can edit their own contacts
    return contact.userId == user.uid;
  }

  // Get all contacts (one-time fetch)
  Future<List<Contact>> getAllContacts() async {
    final snapshot = await _firestore.collection('contacts').orderBy('name').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Contact.fromJson(data);
    }).toList();
  }

  // Get contact by ID
  Future<Contact?> getContactById(String id) async {
    final doc = await _firestore.collection('contacts').doc(id).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Contact.fromJson(data);
    }
    return null;
  }

  // Search contacts
  Future<List<Contact>> searchContacts(String query) async {
    if (query.isEmpty) return await getAllContacts();

    final snapshot = await _firestore
        .collection('contacts')
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Contact.fromJson(data);
    }).toList();
  }
}
