// المسار: lib/features/contacts/domain/use_cases/add_contact_usecase.dart

import '../../data/repository/contacts_repository.dart';
import '../models/contact_model.dart';

class AddContactUseCase {
  final ContactsRepository repository;

  AddContactUseCase(this.repository);

  Future<void> call(String currentUserId, String phone) async {
    try {
      // Find contact by phone
      final contact = await repository.findContactByPhone(phone);

      if (contact == null) {
        throw Exception('Contact not found with phone: $phone');
      }

      // Add to contacts
      await repository.addContact(currentUserId, contact.id);
    } catch (e) {
      throw Exception('UseCase: Failed to add contact - $e');
    }
  }
}