// المسار: lib/features/home/single_chat/domain/di/single_chat_di.dart

import 'package:get/get.dart';
import '../../data/data_source/single_chat_remote_data_source.dart';
import '../../data/repository/single_chat_repository_impl.dart';
import '../../presentation/controller/single_chat_controller.dart';

class SingleChatDI {
  static void init() {
    print('🔄 Initializing SingleChat DI...');

    // Data Source
    if (!Get.isRegistered<SingleChatRemoteDataSource>()) {
      Get.lazyPut<SingleChatRemoteDataSource>(
            () => SingleChatRemoteDataSource(),
        fenix: true,
      );
      print('✅ SingleChatRemoteDataSource registered');
    }

    // Repository
    if (!Get.isRegistered<SingleChatRepositoryImpl>()) {
      Get.lazyPut<SingleChatRepositoryImpl>(
            () => SingleChatRepositoryImpl(Get.find<SingleChatRemoteDataSource>()),
        fenix: true,
      );
      print('✅ SingleChatRepositoryImpl registered');
    }

    // Controller
    if (!Get.isRegistered<SingleChatController>()) {
      Get.lazyPut<SingleChatController>(
            () => SingleChatController(repository: Get.find<SingleChatRepositoryImpl>()),
        fenix: true,
      );
      print('✅ SingleChatController registered');
    }
  }

  static SingleChatController get controller {
    if (!Get.isRegistered<SingleChatController>()) {
      init();
    }
    return Get.find<SingleChatController>();
  }

  static void dispose() {
    print('🧹 Disposing SingleChat DI...');

    if (Get.isRegistered<SingleChatController>()) {
      Get.delete<SingleChatController>();
      print('✅ SingleChatController disposed');
    }
    if (Get.isRegistered<SingleChatRepositoryImpl>()) {
      Get.delete<SingleChatRepositoryImpl>();
      print('✅ SingleChatRepositoryImpl disposed');
    }
    if (Get.isRegistered<SingleChatRemoteDataSource>()) {
      Get.delete<SingleChatRemoteDataSource>();
      print('✅ SingleChatRemoteDataSource disposed');
    }
  }
}