import 'package:get/get.dart';
import '../../domain/di/auth_di.dart';
import '../../domain/models/user_model.dart';

class AuthController extends GetxController {
  final AuthDI di = AuthDI();

  // Observables for state management
  var isLoading = false.obs;
  var isOtpSent = false.obs;
  var isVerified = false.obs;
  var user = Rxn<UserModel>();
  var errorMessage = "".obs;

  /// Send OTP to the user phone number
  Future<void> sendOtp(String phone) async {
    if (phone.isEmpty) {
      errorMessage.value = "Phone number cannot be empty";
      return;
    }

    isLoading.value = true;
    errorMessage.value = "";

    try {
      final success = await di.sendOtpUseCase(phone);

      if (success) {
        isOtpSent.value = true;
      } else {
        errorMessage.value = "Failed to send OTP. Please try again.";
      }
    } catch (e) {
      errorMessage.value = "Error sending OTP: $e";
    } finally {
      isLoading.value = false;
    }
  }

  /// Verify OTP and handle user registration or login
  Future<void> verifyOtp(String phone, String otp, String name) async {
    if (otp.isEmpty) {
      errorMessage.value = "OTP code cannot be empty";
      return;
    }

    isLoading.value = true;
    errorMessage.value = "";

    try {
      final result = await di.verifyOtpUseCase(phone, otp, name);

      if (result != null) {
        user.value = result;
        isVerified.value = true;

        // Later: Save the user locally (SharedPreferences or secure storage)
        // so the app skips login next time.
      } else {
        errorMessage.value = "Invalid OTP or verification failed.";
      }
    } catch (e) {
      errorMessage.value = "Error verifying OTP: $e";
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset the controller state (used if user cancels verification)
  void reset() {
    isOtpSent.value = false;
    isVerified.value = false;
    errorMessage.value = "";
    user.value = null;
  }
}
