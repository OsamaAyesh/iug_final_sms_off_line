
import 'dart:io';
import '../../data/repository/profile_repository.dart';

class UploadProfileImageUseCase {
  final ProfileRepository repository;

  UploadProfileImageUseCase(this.repository);

  Future<String> call(String userId, File imageFile) async {
    try {
      return await repository.uploadProfileImage(userId, imageFile);
    } catch (e) {
      throw Exception('UseCase: Failed to upload profile image - $e');
    }
  }
}