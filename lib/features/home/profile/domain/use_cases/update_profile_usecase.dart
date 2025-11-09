
import '../../data/repository/profile_repository.dart';
import '../models/profile_model.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<void> call(String userId, ProfileModel profile) async {
    try {
      await repository.updateProfile(userId, profile);
    } catch (e) {
      throw Exception('UseCase: Failed to update profile - $e');
    }
  }
}