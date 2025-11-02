import 'package:app_mobile/core/error_handler/data_source_extension.dart';
import 'package:app_mobile/core/error_handler/response_code.dart';
import 'package:app_mobile/core/error_handler/type_handler_enum.dart';
import 'package:app_mobile/core/extensions/extensions.dart';
import 'package:app_mobile/core/storage/local/app_settings_prefs.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../constants/constants/constants.dart';
import '../../constants/di/dependency_injection.dart';
import '../resources/manager_strings.dart';
import '../routes/routes.dart';
import 'failure.dart';

class ErrorHandler implements Exception {
  late Failure failure;
  AppSettingsPrefs appSettings = instance<AppSettingsPrefs>();

  ErrorHandler.handle(dynamic error) {
    if (error is DioException) {
      final response = error.response;
      final statusCode = response?.statusCode ?? ResponseCode.badRequest;
      final data = response?.data;

      if (response?.statusCode == ResponseCode.unAuthorized) {
        Future.delayed(
          const Duration(
            seconds: Constants.sessionFinishedDuration,
          ),
          () {
            appSettings.clear();
            Get.offAllNamed(Routes.splash);
          },
        );
        failure = Failure(
          response!.statusCode.onNull(),
          ManagerStrings.sessionFinished,
        );
      } else if (data != null) {
        final errorMessage = data[Constants.message] ??
            data[Constants.error]?[Constants.message] ??
            data[Constants.errors].values.first.first ??
            Constants.error;

        failure = Failure(
          statusCode,
          errorMessage,
        );
      } else {
        failure = Failure(
          statusCode,
          Constants.error,
        );
      }
    } else {
      failure = TypeHandlerEnum.unknown.getFailure();
    }
  }
}
