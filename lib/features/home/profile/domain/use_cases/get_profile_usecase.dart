import '../../data/repository/profile_repository.dart';
import '../models/profile_model.dart';

class GetProfileUseCase {
  final ProfileRepository repository;

  GetProfileUseCase(this.repository);

  Future<ProfileModel> call(String userId) async {
    try {
      return await repository.getProfile(userId);
    } catch (e) {
      throw Exception('UseCase: Failed to get profile - $e');
    }
  }
}