// المسار: lib/features/home/group_chat/domain/di/chat_group_di.dart

import 'package:get/get.dart';
import '../../data/data_source/chat_group_remote_data_source.dart';
import '../../data/repository/chat_group_repository_impl.dart';
import '../../presentation/controller/chat_group_controller.dart';

class ChatGroupDI {
  static void init() {
    // Data Source
    if (!Get.isRegistered<ChatGroupRemoteDataSource>()) {
      Get.lazyPut<ChatGroupRemoteDataSource>(
            () => ChatGroupRemoteDataSource(),
      );
    }

    // Repository
    if (!Get.isRegistered<ChatGroupRepositoryImpl>()) {
      Get.lazyPut<ChatGroupRepositoryImpl>(
            () => ChatGroupRepositoryImpl(Get.find<ChatGroupRemoteDataSource>()),
      );
    }

    // Controller
    if (!Get.isRegistered<ChatGroupController>()) {
      Get.put<ChatGroupController>(
        ChatGroupController(repository: Get.find<ChatGroupRepositoryImpl>()),
      );
    }
  }

  static void dispose() {
    if (Get.isRegistered<ChatGroupController>()) {
      Get.delete<ChatGroupController>();
    }
    if (Get.isRegistered<ChatGroupRepositoryImpl>()) {
      Get.delete<ChatGroupRepositoryImpl>();
    }
    if (Get.isRegistered<ChatGroupRemoteDataSource>()) {
      Get.delete<ChatGroupRemoteDataSource>();
    }
  }
}