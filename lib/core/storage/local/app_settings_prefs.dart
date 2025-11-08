import 'package:app_mobile/core/extensions/extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/shared_prefs_constants/shared_prefs_constants.dart';

class AppSettingsPrefs {
  final SharedPreferences _sharedPreferences;

  AppSettingsPrefs(this._sharedPreferences);

  /// Clear the shared prefs
  clear() {
    _sharedPreferences.clear();
  }

  // ================================
  // 🔹 الدوال الجديدة المطلوبة
  // ================================

  /// حفظ أي قيمة نصية
  Future<void> setString(String key, String value) async {
    await _sharedPreferences.setString(key, value);
  }

  /// جلب أي قيمة نصية
  String? getString(String key) {
    return _sharedPreferences.getString(key);
  }

  /// حفظ معرف المستخدم
  Future<void> setUserId(String userId) async {
    await _sharedPreferences.setString(
      SharedPrefsConstants.userId,
      userId,
    );
  }

  /// جلب معرف المستخدم
  String? getUserId() {
    return _sharedPreferences.getString(SharedPrefsConstants.userId);
  }

  /// حفظ اسم المستخدم
  Future<void> setUserName(String name) async {
    await _sharedPreferences.setString(
      SharedPrefsConstants.userName,
      name,
    );
  }

  /// جلب اسم المستخدم
  String? getUserName() {
    return _sharedPreferences.getString(SharedPrefsConstants.userName);
  }

  /// حفظ رقم هاتف المستخدم
  Future<void> setUserPhone(String phone) async {
    await _sharedPreferences.setString(
      SharedPrefsConstants.userPhone,
      phone,
    );
  }

  /// جلب رقم هاتف المستخدم
  String? getUserPhone() {
    return _sharedPreferences.getString(SharedPrefsConstants.userPhone);
  }

  /// حفظ الصورة الشخصية للمستخدم
  Future<void> setUserImage(String imageUrl) async {
    await _sharedPreferences.setString(
      SharedPrefsConstants.userImage,
      imageUrl,
    );
  }

  /// جلب الصورة الشخصية للمستخدم
  String? getUserImage() {
    return _sharedPreferences.getString(SharedPrefsConstants.userImage);
  }

  /// حفظ البريد الإلكتروني للمستخدم
  Future<void> setUserEmail(String email) async {
    await _sharedPreferences.setString(
      SharedPrefsConstants.userEmail,
      email,
    );
  }

  /// جلب البريد الإلكتروني للمستخدم
  String? getUserEmail() {
    return _sharedPreferences.getString(SharedPrefsConstants.userEmail);
  }

  /// التحقق من وجود بيانات مستخدم مسجل
  bool hasUserData() {
    return getUserId() != null &&
        getUserId()!.isNotEmpty &&
        getUserLoggedIn();
  }

  /// جلب جميع بيانات المستخدم كـ Map
  Map<String, String?> getUserData() {
    return {
      'user_id': getUserId(),
      'user_name': getUserName(),
      'user_phone': getUserPhone(),
      'user_email': getUserEmail(),
      'user_image': getUserImage(),
      'token': getToken(),
    };
  }

  /// مسح بيانات المستخدم فقط (مع الاحتفاظ بالإعدادات الأخرى)
  Future<void> clearUserData() async {
    await _sharedPreferences.remove(SharedPrefsConstants.userId);
    await _sharedPreferences.remove(SharedPrefsConstants.userName);
    await _sharedPreferences.remove(SharedPrefsConstants.userPhone);
    await _sharedPreferences.remove(SharedPrefsConstants.userEmail);
    await _sharedPreferences.remove(SharedPrefsConstants.userImage);
    await _sharedPreferences.remove(SharedPrefsConstants.token);
    await _sharedPreferences.setBool(SharedPrefsConstants.isLoggedIn, false);
  }

  // ================================
  // 🔹 الدوال الأصلية (موجودة سابقاً)
  // ================================

  /// Setting up the app locale
  Future<void> setLocale({
    required String locale,
  }) async {
    await _sharedPreferences.setString(
      SharedPrefsConstants.locale,
      locale,
    );
  }

  /// Get the app locale
  String getLocale() {
    return _sharedPreferences
        .getString(
      SharedPrefsConstants.locale,
    )
        .pareWithDefaultLocale();
  }

  /// Set if the outBoarding viewed
  Future<void> setOutBoardingScreenViewed() async {
    await _sharedPreferences.setBool(
      SharedPrefsConstants.outBoardingViewed,
      true,
    );
  }

  /// Return true if outBoarding viewed
  bool getOutBoardingScreenViewed() {
    return _sharedPreferences
        .getBool(
      SharedPrefsConstants.outBoardingViewed,
    )
        .onNull();
  }

  /// Set if the user logged in is true
  Future<void> setUserLoggedIn() async {
    await _sharedPreferences.setBool(
      SharedPrefsConstants.isLoggedIn,
      true,
    );
  }

  /// Get if the user logged
  bool getUserLoggedIn() {
    return _sharedPreferences
        .getBool(
      SharedPrefsConstants.isLoggedIn,
    )
        .onNull();
  }

  /// Set the user token
  Future<void> setToken({
    required String token,
  }) async {
    await _sharedPreferences.setString(
      SharedPrefsConstants.token,
      token,
    );
  }

  /// Get the user token
  String getToken() {
    return _sharedPreferences.getString(SharedPrefsConstants.token).onNull();
  }

  // في ملف app_settings_prefs.dart
  Future<void> cacheUserData({
    required String userId,
    required String name,
    required String phone,
  }) async {
    try {
      setUserLoggedIn();
      setUserId(userId);
      setUserName(name);
      setUserPhone(phone);

      // حفظ فوري
      await _sharedPreferences.commit();

      print('✅ User data cached: $userId, $name');
    } catch (e) {
      print('❌ Error caching user data: $e');
      rethrow;
    }
  }
}