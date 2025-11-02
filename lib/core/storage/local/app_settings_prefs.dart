import 'package:app_mobile/core/extensions/extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/shared_prefs_constants/shared_prefs_constants.dart';

/// A class defined for save the data to shared preferences
class AppSettingsPrefs {
  final SharedPreferences _sharedPreferences;

  /// Clear the shared prefs
  clear() {
    _sharedPreferences.clear();
  }

  AppSettingsPrefs(
    this._sharedPreferences,
  );

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
}
