// المسار: lib/features/home/home_feature/domain/di/chat_di.dart

import 'package:get/get.dart';
import '../../data/data_source/chat_remote_data_source.dart';
import '../../data/repository/chat_repository_impl.dart';
import '../use_cases/get_chat_rooms_use_case.dart';
import '../../presentation/controller/chat_controller.dart';

class ChatDI {
  static void init() {
    print('🔄 Initializing Chat DI...');

    // Data Source
    if (!Get.isRegistered<ChatRemoteDataSource>()) {
      Get.lazyPut<ChatRemoteDataSource>(
            () => ChatRemoteDataSource(),
        fenix: true,
      );
      print('✅ ChatRemoteDataSource registered');
    }

    // Repository
    if (!Get.isRegistered<ChatRepositoryImpl>()) {
      Get.lazyPut<ChatRepositoryImpl>(
            () => ChatRepositoryImpl(remote: Get.find<ChatRemoteDataSource>()),
        fenix: true,
      );
      print('✅ ChatRepositoryImpl registered');
    }

    // Use Case
    if (!Get.isRegistered<GetChatRoomsUseCase>()) {
      Get.lazyPut<GetChatRoomsUseCase>(
            () => GetChatRoomsUseCase(Get.find<ChatRepositoryImpl>()),
        fenix: true,
      );
      print('✅ GetChatRoomsUseCase registered');
    }

    // Controller
    if (!Get.isRegistered<ChatController>()) {
      Get.lazyPut<ChatController>(
            () => ChatController(),
        fenix: true,
      );
      print('✅ ChatController registered');
    }
  }

  static ChatController get controller {
    if (!Get.isRegistered<ChatController>()) {
      init();
    }
    return Get.find<ChatController>();
  }

  static void dispose() {
    print('🧹 Disposing Chat DI...');

    if (Get.isRegistered<ChatController>()) {
      Get.delete<ChatController>();
      print('✅ ChatController disposed');
    }
    if (Get.isRegistered<GetChatRoomsUseCase>()) {
      Get.delete<GetChatRoomsUseCase>();
      print('✅ GetChatRoomsUseCase disposed');
    }
    if (Get.isRegistered<ChatRepositoryImpl>()) {
      Get.delete<ChatRepositoryImpl>();
      print('✅ ChatRepositoryImpl disposed');
    }
    if (Get.isRegistered<ChatRemoteDataSource>()) {
      Get.delete<ChatRemoteDataSource>();
      print('✅ ChatRemoteDataSource disposed');
    }
  }
}