import 'package:get/get.dart';
import '../resources/manager_strings.dart';
import '../routes/routes.dart';
import 'failure.dart';
import 'response_code.dart';
import 'type_handler_enum.dart';

extension DataSourceExtension on TypeHandlerEnum {
  Failure getFailure() {
    switch (this) {
      case TypeHandlerEnum.success:
        return Failure(
          ResponseCode.success,
          ManagerStrings.success,
        );
      case TypeHandlerEnum.noContent:
        return Failure(
          ResponseCode.noContent,
          ManagerStrings.noContent,
        );
      case TypeHandlerEnum.badRequest:
        return Failure(
          ResponseCode.badRequest,
          ManagerStrings.badRequest,
        );
      case TypeHandlerEnum.forbidden:
        return Failure(
          ResponseCode.forbidden,
          ManagerStrings.forbidden,
        );
      case TypeHandlerEnum.unauthorised:
        Get.offAllNamed(
          Routes.splash,
        );
        return Failure(
          ResponseCode.unAuthorized,
          ManagerStrings.unAuthorized,
        );
      case TypeHandlerEnum.notFound:
        return Failure(
          ResponseCode.notFound,
          ManagerStrings.notFound,
        );
      case TypeHandlerEnum.internalServerError:
        return Failure(
          ResponseCode.internalServerError,
          ManagerStrings.internalServerError,
        );
      case TypeHandlerEnum.connectTimeout:
        return Failure(
          ResponseCode.connectTimeOut,
          ManagerStrings.connectTimeOut,
        );
      case TypeHandlerEnum.cancel:
        return Failure(
          ResponseCode.cancel,
          ManagerStrings.cancel,
        );
      case TypeHandlerEnum.receiveTimeout:
        return Failure(
          ResponseCode.receiveTimeOut,
          ManagerStrings.receiveTimeOut,
        );
      case TypeHandlerEnum.sendTimeout:
        return Failure(
          ResponseCode.sendTimeOut,
          ManagerStrings.sendTimeOut,
        );
      case TypeHandlerEnum.cacheError:
        return Failure(
          ResponseCode.cacheError,
          ManagerStrings.cacheError,
        );
      case TypeHandlerEnum.noInternetConnection:
        return Failure(
          ResponseCode.noInternetConnection,
          ManagerStrings.noInternetConnection,
        );
      default:
        return Failure(
          ResponseCode.unKnown,
          ManagerStrings.unKnown,
        );
    }
  }
}
