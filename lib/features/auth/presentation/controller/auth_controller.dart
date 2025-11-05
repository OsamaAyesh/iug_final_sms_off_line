// lib/features/auth/presentation/controller/auth_controller.dart

import 'package:app_mobile/core/storage/local/app_settings_prefs.dart';
import 'package:app_mobile/core/util/snack_bar.dart';
import 'package:app_mobile/core/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/di/auth_di.dart';
import '../../domain/models/user_model.dart';
import '../pages/success_verify_screen.dart';

class AuthController extends GetxController {
  final AuthDI di = Get.find<AuthDI>();

  /// App Settings Prefs
  late AppSettingsPrefs _prefs;

  var isLoading = false.obs;
  var isOtpSent = false.obs;
  var isVerified = false.obs;
  var user = Rxn<UserModel>();
  var errorMessage = "".obs;

  final phoneRegex = RegExp(r'^[0-9]{9,15}$');

  @override
  void onInit() {
    super.onInit();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = AppSettingsPrefs(prefs);
  }

  /// Validate user input before sending OTP
  bool validateInputs(String name, String phone) {
    if (name.trim().isEmpty) {
      AppSnackbar.warning("الرجاء إدخال الأسم الكامل");
      return false;
    }

    if (phone.trim().isEmpty) {
      AppSnackbar.warning("الرجاء إدخال رقم الهاتف");
      return false;
    }

    if (!phoneRegex.hasMatch(phone)) {
      AppSnackbar.warning("بنيبة الرقم المدخل غير صحيحة");
      return false;
    }

    return true;
  }

  /// Send OTP with validation
  Future<void> sendOtp(String name, String phone) async {
    if (!validateInputs(name, phone)) return;

    _showLoading();

    try {
      final success = await di.sendOtpUseCase(phone);

      if (success) {
        isOtpSent.value = true;
        AppSnackbar.success("تم إرسال كود التحقق بنجاح");
      } else {
        AppSnackbar.error("فشل في إرسال كود التحقق");
      }
    } catch (e) {
      AppSnackbar.error(e.toString());
    } finally {
      _hideLoading();
    }
  }

  /// Verify OTP
  Future<void> verifyOtp(String phone, String otp, String name) async {
    if (otp.isEmpty) {
      AppSnackbar.warning(
        title: "التحقق",
        "يرجى إدخال رقم التحقق",
      );
      return;
    }

    _showLoading();
    try {
      final result = await di.verifyOtpUseCase(phone, otp, name);
      if (result != null) {
        user.value = result;
        isVerified.value = true;
        AppSnackbar.success("تم التحقق بنجاح");

        /// حفظ حالة المستخدم في SharedPreferences
        await _prefs.setUserLoggedIn();
        // if (result.token != null && result.token!.isNotEmpty) {
        //   await _prefs.setToken(token: result.token!);
        // }

        /// يمكنك أيضًا حفظ رقم الهاتف أو الاسم إذا أردت مستقبلاً
        /// await _prefs.setUserPhone(phone);
        /// await _prefs.setUserName(name);

        // Redirect after delay
        Future.delayed(const Duration(seconds: 1), () {
          Get.offAll(() => const SuccessVerifyScreen());
        });
      } else {
        AppSnackbar.error("كود التحقق غير صحيح");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      _hideLoading();
    }
  }

  /// Loading Overlay
  void _showLoading() {
    if (!isLoading.value && !(Get.isDialogOpen ?? false)) {
      isLoading.value = true;
      Get.dialog(
        const Center(child: LoadingWidget()),
        barrierDismissible: false,
      );
    }
  }

  void _hideLoading() {
    if (isLoading.value) {
      isLoading.value = false;
      if (Get.isDialogOpen ?? false) Get.back();
    }
  }

  /// Logout (اختياري)
  Future<void> logout() async {
    await _prefs.clear();
    isVerified.value = false;
    isOtpSent.value = false;
    user.value = null;
    Get.offAllNamed('/login');
  }
}
