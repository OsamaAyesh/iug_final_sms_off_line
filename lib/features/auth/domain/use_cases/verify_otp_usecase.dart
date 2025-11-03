import '../models/user_model.dart';

abstract class VerifyOtpRepository {
  Future<UserModel?> verifyOtp(String phone, String otp, String name);
}

class VerifyOtpUseCase {
  final VerifyOtpRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<UserModel?> call(String phone, String otp, String name) async {
    return await repository.verifyOtp(phone, otp, name);
  }
}
