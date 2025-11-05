// المسار: lib/features/contacts/data/repository/contacts_repository_impl.dart

import '../../domain/models/contact_model.dart';
import '../data_source/contacts_remote_data_source.dart';
import '../mapper/contact_mapper.dart';
import 'contacts_repository.dart';

class ContactsRepositoryImpl implements ContactsRepository {
  final ContactsRemoteDataSource remoteDataSource;

  ContactsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ContactModel>> getAllContacts(String currentUserId) async {
    try {
      final responses = await remoteDataSource.getAllContacts(currentUserId);
      return ContactMapper.toModelList(responses);
    } catch (e) {
      throw Exception('Repository: Failed to load contacts - $e');
    }
  }

  @override
  Future<ContactModel?> findContactByPhone(String phone) async {
    try {
      final response = await remoteDataSource.findContactByPhone(phone);
      if (response == null) return null;
      return ContactMapper.toModel(response);
    } catch (e) {
      throw Exception('Repository: Failed to find contact - $e');
    }
  }

  @override
  Future<void> addContact(String currentUserId, String contactId) async {
    try {
      await remoteDataSource.addContact(currentUserId, contactId);
    } catch (e) {
      throw Exception('Repository: Failed to add contact - $e');
    }
  }

  @override
  Future<void> removeContact(String currentUserId, String contactId) async {
    try {
      await remoteDataSource.removeContact(currentUserId, contactId);
    } catch (e) {
      throw Exception('Repository: Failed to remove contact - $e');
    }
  }

  @override
  Future<ContactModel?> getContactById(String userId) async {
    try {
      final response = await remoteDataSource.getContactById(userId);
      if (response == null) return null;
      return ContactMapper.toModel(response);
    } catch (e) {
      throw Exception('Repository: Failed to get contact - $e');
    }
  }
}