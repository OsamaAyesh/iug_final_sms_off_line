// المسار: lib/features/contacts/domain/repository/contacts_repository.dart

import '../../domain/models/contact_model.dart';

abstract class ContactsRepository {
  Future<List<ContactModel>> getAllContacts(String currentUserId);
  Future<ContactModel?> findContactByPhone(String phone);
  Future<void> addContact(String currentUserId, String contactId);
  Future<void> removeContact(String currentUserId, String contactId);
  Future<ContactModel?> getContactById(String userId);
}