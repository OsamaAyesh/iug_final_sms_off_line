import '../../data/data_source/auth_remote_data_source.dart';
import '../../data/repository/auth_repository_impl.dart';
import '../use_cases/send_otp_usecase.dart';
import '../use_cases/verify_otp_usecase.dart';

class AuthDI {
  late final AuthRemoteDataSource _remote;
  late final AuthRepositoryImpl _repository;
  late final SendOtpUseCase sendOtpUseCase;
  late final VerifyOtpUseCase verifyOtpUseCase;

  AuthDI() {
    _remote = AuthRemoteDataSource();
    _repository = AuthRepositoryImpl(remote: _remote);

    sendOtpUseCase = SendOtpUseCase(_repository);
    verifyOtpUseCase = VerifyOtpUseCase(_repository);
  }
}
