// المسار: lib/features/contacts/data/data_source/contacts_remote_data_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../request/add_contact_request.dart';
import '../response/contact_response.dart';

abstract class ContactsRemoteDataSource {
  Future<List<ContactResponse>> getAllContacts(String currentUserId);
  Future<ContactResponse?> findContactByPhone(String phone);
  Future<void> addContact(String currentUserId, String contactId);
  Future<void> removeContact(String currentUserId, String contactId);
  Future<ContactResponse?> getContactById(String userId);
}

class ContactsRemoteDataSourceImpl implements ContactsRemoteDataSource {
  final FirebaseFirestore _firestore;

  ContactsRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<ContactResponse>> getAllContacts(String currentUserId) async {
    try {
      final snapshot = await _firestore.collection('users').get();

      final contacts = <ContactResponse>[];
      for (var doc in snapshot.docs) {
        if (doc.id != currentUserId) {
          contacts.add(ContactResponse.fromJson(doc.id, doc.data()));
        }
      }

      return contacts;
    } catch (e) {
      throw Exception('Failed to load contacts: $e');
    }
  }

  @override
  Future<ContactResponse?> findContactByPhone(String phone) async {
    try {
      final normalizedPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

      final snapshot = await _firestore
          .collection('users')
          .where('phoneCanon', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      return ContactResponse.fromJson(doc.id, doc.data());
    } catch (e) {
      throw Exception('Failed to find contact: $e');
    }
  }

  @override
  Future<void> addContact(String currentUserId, String contactId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(contactId)
          .set({
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add contact: $e');
    }
  }

  @override
  Future<void> removeContact(String currentUserId, String contactId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('contacts')
          .doc(contactId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove contact: $e');
    }
  }

  @override
  Future<ContactResponse?> getContactById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      return ContactResponse.fromJson(doc.id, doc.data()!);
    } catch (e) {
      throw Exception('Failed to get contact: $e');
    }
  }
}