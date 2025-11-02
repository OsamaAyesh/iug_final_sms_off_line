import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/internet_checker/interent_checker.dart';
import '../../core/network/app_api.dart';
import '../../core/network/dio_factory.dart';
import '../../core/storage/local/app_settings_prefs.dart';

final instance = GetIt.instance;

/// Init the base module when open app
initModule() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await dotenv.load(fileName: '.env');

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final SharedPreferences sharedPrefs = await SharedPreferences.getInstance();

  if (!GetIt.I.isRegistered<SharedPreferences>()) {
    instance.registerLazySingleton<SharedPreferences>(() => sharedPrefs);
  }

  if (!GetIt.I.isRegistered<AppSettingsPrefs>()) {
    instance.registerLazySingleton<AppSettingsPrefs>(
        () => AppSettingsPrefs(instance()));
  }
  // This is not important code
  // @todo: remove this code
  // AppSettingsPrefs _app = instance<AppSettingsPrefs>();
  // var pref = await SharedPreferences.getInstance();
  // pref.clear();

  if (!GetIt.I.isRegistered<NetworkInfo>()) {
    instance.registerLazySingleton<NetworkInfo>(
        () => NetworkInfoImp(InternetConnectionCheckerPlus()));
  }

  if (!GetIt.I.isRegistered<DioFactory>()) {
    instance.registerLazySingleton<DioFactory>(() => DioFactory());
  }
  Dio dio = await instance<DioFactory>().getDio();
  if (!GetIt.I.isRegistered<AppService>()) {
    instance.registerLazySingleton<AppService>(() => AppService(dio));
  }
}
