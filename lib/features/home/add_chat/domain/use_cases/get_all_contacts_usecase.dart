// المسار: lib/features/contacts/domain/use_cases/get_all_contacts_usecase.dart

import '../../data/repository/contacts_repository.dart';
import '../models/contact_model.dart';

class GetAllContactsUseCase {
  final ContactsRepository repository;

  GetAllContactsUseCase(this.repository);

  Future<List<ContactModel>> call(String currentUserId) async {
    try {
      return await repository.getAllContacts(currentUserId);
    } catch (e) {
      throw Exception('UseCase: Failed to get contacts - $e');
    }
  }
}