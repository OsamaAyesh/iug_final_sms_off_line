import 'package:get/get.dart';
import '../../data/data_source/profile_remote_data_source.dart';
import '../../data/repository/profile_repository.dart';
import '../../data/repository/profile_repository_impl.dart';
import '../../pages/controller/profile_controller.dart';
import '../use_cases/get_profile_usecase.dart';
import '../use_cases/update_profile_usecase.dart';
import '../use_cases/upload_profile_image_usecase.dart';

class ProfileDI {
  static void init() {
    // Data Source
    Get.lazyPut<ProfileRemoteDataSource>(
          () => ProfileRemoteDataSourceImpl(),
      fenix: true,
    );

    // Repository
    Get.lazyPut<ProfileRepository>(
          () => ProfileRepositoryImpl(
        remoteDataSource: Get.find<ProfileRemoteDataSource>(),
      ),
      fenix: true,
    );

    // Use Cases
    Get.lazyPut(
          () => GetProfileUseCase(Get.find<ProfileRepository>()),
      fenix: true,
    );

    Get.lazyPut(
          () => UpdateProfileUseCase(Get.find<ProfileRepository>()),
      fenix: true,
    );

    Get.lazyPut(
          () => UploadProfileImageUseCase(Get.find<ProfileRepository>()),
      fenix: true,
    );

    // Controller
    Get.lazyPut(
          () => ProfileController(
        getProfileUseCase: Get.find<GetProfileUseCase>(),
        updateProfileUseCase: Get.find<UpdateProfileUseCase>(),
        uploadProfileImageUseCase: Get.find<UploadProfileImageUseCase>(),
      ),
    );
  }

  static void dispose() {
    Get.delete<ProfileController>();
    Get.delete<GetProfileUseCase>();
    Get.delete<UpdateProfileUseCase>();
    Get.delete<UploadProfileImageUseCase>();
    Get.delete<ProfileRepository>();
    Get.delete<ProfileRemoteDataSource>();
  }
}