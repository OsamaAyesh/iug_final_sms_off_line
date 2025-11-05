import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../domain/di/chat_di.dart';
import '../../domain/models/chat_room_model.dart';

class ChatController extends GetxController {
  final ChatDI di = ChatDI();

  var isLoading = true.obs;
  var selectedTab = 0.obs;
  var allChats = <ChatRoomModel>[].obs;
  var filteredChats = <ChatRoomModel>[].obs;
  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _loadAll();
  }

  Future<void> _loadAll() async {
    isLoading.value = true;
    final all = await di.getChatRoomsUseCase.executeAll();
    allChats.assignAll(all);
    filteredChats.assignAll(all);
    isLoading.value = false;
  }

  void changeTab(int index) {
    selectedTab.value = index;
    _filterChats();
  }

  void onSearchChanged(String query) {
    _filterChats(query: query);
  }

  void _filterChats({String query = ""}) {
    List<ChatRoomModel> result = [];

    if (selectedTab.value == 0) {
      result = allChats;
    } else if (selectedTab.value == 1) {
      result = allChats.where((e) => !e.isGroup).toList();
    } else {
      result = allChats.where((e) => e.isGroup).toList();
    }

    if (query.isNotEmpty) {
      result = result
          .where((chat) =>
      chat.name.toLowerCase().contains(query.toLowerCase()) ||
          chat.lastMessage.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    filteredChats.assignAll(result);
  }
}
