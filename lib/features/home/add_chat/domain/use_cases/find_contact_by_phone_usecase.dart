// المسار: lib/features/contacts/domain/use_cases/find_contact_by_phone_usecase.dart

import '../../data/repository/contacts_repository.dart';
import '../models/contact_model.dart';

class FindContactByPhoneUseCase {
  final ContactsRepository repository;

  FindContactByPhoneUseCase(this.repository);

  Future<ContactModel?> call(String phone) async {
    try {
      return await repository.findContactByPhone(phone);
    } catch (e) {
      throw Exception('UseCase: Failed to find contact - $e');
    }
  }
}