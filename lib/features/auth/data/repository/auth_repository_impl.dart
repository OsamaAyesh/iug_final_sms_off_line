import '../../domain/models/user_model.dart';
import '../../domain/use_cases/send_otp_usecase.dart';
import '../../domain/use_cases/verify_otp_usecase.dart';
import '../data_source/auth_remote_data_source.dart';
import '../request/send_otp_request.dart';

class AuthRepositoryImpl implements SendOtpRepository, VerifyOtpRepository {
  final AuthRemoteDataSource remote;

  AuthRepositoryImpl({required this.remote});

  @override
  Future<bool> sendOtp(String phone) async {
    final response = await remote.sendOtp(SendOtpRequest(phone: phone));
    return response.success;
  }

  @override
  Future<UserModel?> verifyOtp(String phone, String otp, String name) async {
    final userData = await remote.verifyOtp(phone, otp, name);
    if (userData == null) return null;
    return UserModel.fromJson(userData);
  }
}
