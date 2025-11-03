
abstract class SendOtpRepository {
  Future<bool> sendOtp(String phone);
}

class SendOtpUseCase {
  final SendOtpRepository repository;

  SendOtpUseCase(this.repository);

  Future<bool> call(String phone) async {
    return await repository.sendOtp(phone);
  }
}
