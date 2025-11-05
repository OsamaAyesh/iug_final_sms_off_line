import 'package:get/get.dart';
import '../../data/data_source/chat_group_remote_data_source.dart';
import '../../data/repository/chat_group_repository_impl.dart';
import '../../presentation/controller/chat_group_controller.dart';

class ChatGroupDI {
  static void init() {
    print('🔄 Initializing ChatGroup DI...');

    // Data Source
    if (!Get.isRegistered<ChatGroupRemoteDataSource>()) {
      Get.lazyPut<ChatGroupRemoteDataSource>(
            () => ChatGroupRemoteDataSource(),
        fenix: true,
      );
      print('✅ ChatGroupRemoteDataSource registered');
    }

    // Repository
    if (!Get.isRegistered<ChatGroupRepositoryImpl>()) {
      Get.lazyPut<ChatGroupRepositoryImpl>(
            () => ChatGroupRepositoryImpl(Get.find<ChatGroupRemoteDataSource>()),
        fenix: true,
      );
      print('✅ ChatGroupRepositoryImpl registered');
    }

    // Controller
    if (!Get.isRegistered<ChatGroupController>()) {
      Get.lazyPut<ChatGroupController>(
            () => ChatGroupController(repository: Get.find<ChatGroupRepositoryImpl>()),
        fenix: true,
      );
      print('✅ ChatGroupController registered');
    }
  }

  static ChatGroupController get controller {
    if (!Get.isRegistered<ChatGroupController>()) {
      init();
    }
    return Get.find<ChatGroupController>();
  }

  static void dispose() {
    print('🧹 Disposing ChatGroup DI...');

    if (Get.isRegistered<ChatGroupController>()) {
      Get.delete<ChatGroupController>();
      print('✅ ChatGroupController disposed');
    }
    if (Get.isRegistered<ChatGroupRepositoryImpl>()) {
      Get.delete<ChatGroupRepositoryImpl>();
      print('✅ ChatGroupRepositoryImpl disposed');
    }
    if (Get.isRegistered<ChatGroupRemoteDataSource>()) {
      Get.delete<ChatGroupRemoteDataSource>();
      print('✅ ChatGroupRemoteDataSource disposed');
    }
  }
}