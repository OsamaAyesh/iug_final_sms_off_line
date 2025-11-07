// المسار: lib/features/home/home_feature/presentation/controller/chat_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_mobile/core/storage/local/app_settings_prefs.dart';
import 'package:app_mobile/core/util/snack_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatController extends GetxController {
  static ChatController get to => Get.find<ChatController>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AppSettingsPrefs _prefs;

  // Controllers
  final searchController = TextEditingController();

  // States
  final isLoading = false.obs;
  final selectedTabIndex = 0.obs;
  final hasData = false.obs;
  final hasIndexError = false.obs;
  final isUserLoggedIn = false.obs;

  // Data
  final allChats = <ChatModel>[].obs;
  final filteredChats = <ChatModel>[].obs;

  // Current User
  String currentUserId = '';
  final currentUserImageUrl = Rxn<String>();
  final currentUserName = Rxn<String>();

  // Streams
  StreamSubscription? _groupChatsSubscription;
  StreamSubscription? _privateChatsSubscription;
  StreamSubscription? _userSubscription;

  @override
  void onInit() {
    super.onInit();
    print('🚀 ChatController initialized');

    _initController().then((_) {
      if (isUserLoggedIn.value) {
        _listenToChats();
      }
    });

    searchController.addListener(() {
      _filterChats(searchController.text);
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    _groupChatsSubscription?.cancel();
    _privateChatsSubscription?.cancel();
    _userSubscription?.cancel();
    super.onClose();
  }

  // ================================
  // 🔸 تهيئة الكونترولر
  // ================================

  Future<void> _initController() async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      _prefs = AppSettingsPrefs(sharedPrefs);

      await _initCurrentUser();

    } catch (e) {
      print('❌ Error initializing controller: $e');
    }
  }

  Future<void> _initCurrentUser() async {
    try {
      currentUserId = _prefs.getUserId() ?? '';

      if (currentUserId.isEmpty) {
        print('❌ No user ID found');
        isUserLoggedIn.value = false;
        _handleNoUser();
        return;
      }

      print('✅ Current user ID: $currentUserId');
      isUserLoggedIn.value = true;
      _loadCurrentUserData();

    } catch (e) {
      print('❌ Error initializing current user: $e');
      isUserLoggedIn.value = false;
      _handleNoUser();
    }
  }

  // ================================
  // 🔸 معالجة حالة عدم وجود مستخدم
  // ================================

  void _handleNoUser() {
    print('👤 No user detected');

    Future.delayed(Duration(milliseconds: 500), () {
      if (Get.isDialogOpen ?? false) Get.back();

      AppSnackbar.warning(
        'يجب تسجيل الدخول أولاً',
      );

      _clearUserDataAndRedirect();
    });
  }

  Future<void> _clearUserDataAndRedirect() async {
    try {
      await _prefs.clearUserData();
      await resetUser();

      Future.delayed(Duration(seconds: 2), () {
        if (Get.currentRoute != '/login') {
          // Get.offAllNamed('/login');
          print('📍 Should redirect to login screen');
        }
      });

    } catch (e) {
      print('❌ Error clearing user data: $e');
    }
  }

  // ================================
  // 🔸 تحميل بيانات المستخدم الحالي
  // ================================

  Future<void> _loadCurrentUserData() async {
    try {
      print('👤 Loading current user data: $currentUserId');

      _userSubscription = _firestore
          .collection('users')
          .doc(currentUserId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          currentUserImageUrl.value = data?['imageUrl'];
          currentUserName.value = data?['name'];
          print('✅ User data loaded: ${currentUserName.value}');
        } else {
          print('⚠️ User document not found: $currentUserId');
          currentUserImageUrl.value = null;
          currentUserName.value = 'مستخدم';
        }
      }, onError: (error) {
        print('❌ Error loading user data: $error');
      });

    } catch (e) {
      print('❌ Error in _loadCurrentUserData: $e');
    }
  }

  // ================================
  // 🔸 الاستماع للمحادثات
  // ================================

  void _listenToChats() {
    if (!isUserLoggedIn.value) {
      print('❌ Cannot listen to chats - user not logged in');
      isLoading.value = false;
      hasData.value = false;
      return;
    }

    isLoading.value = true;
    hasIndexError.value = false;
    print('👂 Listening to real-time chats for user: $currentUserId');

    // محاولة الاستماع للمجموعات
    _tryGroupsListener();

    // محاولة الاستماع للمحادثات الخاصة
    _tryPrivateChatsListener();
  }

  void _tryGroupsListener() {
    _groupChatsSubscription = _firestore
        .collection('groups')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
        print('📥 Real-time groups update: ${snapshot.docs.length} groups');
        hasIndexError.value = false;
        _updateGroupChats(snapshot.docs);
      },
      onError: (error) {
        print('❌ Error in groups listener: $error');
        _handleIndexError(error, 'groups');
      },
    );
  }

  void _tryPrivateChatsListener() {
    _privateChatsSubscription = _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
        print('📥 Real-time private chats update: ${snapshot.docs.length} chats');
        hasIndexError.value = false;
        _updatePrivateChats(snapshot.docs);
      },
      onError: (error) {
        print('❌ Error in private chats listener: $error');
        _handleIndexError(error, 'chat_rooms');
      },
    );
  }

  void _handleIndexError(dynamic error, String collection) {
    isLoading.value = false;
    hasIndexError.value = true;

    final errorStr = error.toString();

    if (errorStr.contains('index') || errorStr.contains('FAILED_PRECONDITION')) {
      print('🔧 Index error detected for $collection');

      Future.delayed(Duration(milliseconds: 500), () {
        AppSnackbar.loading(
          'جاري تحميل المحادثات...',
        );
      });

      _trySimpleQuery(collection);
    }
  }

  void _trySimpleQuery(String collection) {
    print('🔄 Trying simple query for $collection');

    try {
      _firestore
          .collection(collection)
          .where('participants', arrayContains: currentUserId)
          .get()
          .then((snapshot) {
        print('✅ Simple query successful: ${snapshot.docs.length} documents');

        if (collection == 'groups') {
          _updateGroupChats(snapshot.docs);
        } else {
          _updatePrivateChats(snapshot.docs);
        }
      }).catchError((error) {
        print('❌ Simple query also failed: $error');
        _handleNoChatsAvailable();
      });
    } catch (e) {
      print('❌ Error in simple query: $e');
      _handleNoChatsAvailable();
    }
  }

  void _handleNoChatsAvailable() {
    print('💬 No chats available for user $currentUserId');
    hasData.value = false;
    isLoading.value = false;

    Future.delayed(Duration(milliseconds: 500), () {
      AppSnackbar.loading(
        'لا توجد محادثات حالياً. ابدأ محادثة جديدة!',
      );
    });
  }

  void _updateGroupChats(List<QueryDocumentSnapshot> docs) {
    final groupChats = <ChatModel>[];

    for (var doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);

        final chat = ChatModel(
          id: doc.id,
          name: data['name'] ?? 'مجموعة بدون اسم',
          imageUrl: data['imageUrl'] ?? data['groupIcon'] ?? '',
          lastMessage: data['lastMessage'] ?? 'لا توجد رسائل',
          time: _formatTime(data['lastMessageTime']),
          isGroup: true,
          membersCount: participants.length,
          unreadCount: _calculateUnreadCount(data['unreadCount']),
          lastMessageTime: data['lastMessageTime'],
        );

        groupChats.add(chat);
      } catch (e) {
        print('❌ Error parsing group ${doc.id}: $e');
      }
    }

    _updateChatsList(groupChats, true);
    print('✅ Updated ${groupChats.length} groups for user $currentUserId');
  }

  void _updatePrivateChats(List<QueryDocumentSnapshot> docs) {
    final privateChats = <ChatModel>[];

    for (var doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);

        final chat = ChatModel(
          id: doc.id,
          name: data['name'] ?? 'محادثة خاصة',
          imageUrl: data['imageUrl'] ?? '',
          lastMessage: data['lastMessage'] ?? 'لا توجد رسائل',
          time: _formatTime(data['lastMessageTime'] ?? data['timestamp']),
          isGroup: false,
          membersCount: participants.length,
          unreadCount: _calculateUnreadCount(data['unreadCount']),
          lastMessageTime: data['lastMessageTime'] ?? data['timestamp'],
        );

        privateChats.add(chat);
      } catch (e) {
        print('❌ Error parsing private chat ${doc.id}: $e');
      }
    }

    _updateChatsList(privateChats, false);
    print('✅ Updated ${privateChats.length} private chats for user $currentUserId');
  }

  void _updateChatsList(List<ChatModel> newChats, bool areGroups) {
    final otherChats = allChats.where((chat) => chat.isGroup != areGroups).toList();
    allChats.assignAll([...newChats, ...otherChats]);

    _sortChats();
    _applyTabFilter();

    isLoading.value = false;
    hasData.value = allChats.isNotEmpty;

    print('🎯 Total chats: ${allChats.length}, Has data: ${hasData.value}');
  }

  int _calculateUnreadCount(dynamic unreadData) {
    if (unreadData == null) return 0;

    try {
      if (unreadData is Map<String, dynamic>) {
        final count = unreadData[currentUserId];
        return count is int ? count : 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ================================
  // 🔸 Sorting & Filtering
  // ================================

  void _sortChats() {
    allChats.sort((a, b) {
      if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
      if (a.lastMessageTime == null) return 1;
      if (b.lastMessageTime == null) return -1;

      final aTime = a.lastMessageTime is Timestamp
          ? (a.lastMessageTime as Timestamp).toDate()
          : a.lastMessageTime as DateTime?;

      final bTime = b.lastMessageTime is Timestamp
          ? (b.lastMessageTime as Timestamp).toDate()
          : b.lastMessageTime as DateTime?;

      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;

      return bTime.compareTo(aTime);
    });
  }

  void changeTab(int index) {
    selectedTabIndex.value = index;
    _applyTabFilter();
  }

  void _applyTabFilter() {
    List<ChatModel> filtered = [];

    switch (selectedTabIndex.value) {
      case 0: // الكل
        filtered = allChats;
        break;
      case 1: // الدردشات
        filtered = allChats.where((chat) => !chat.isGroup).toList();
        break;
      case 2: // المجموعات
        filtered = allChats.where((chat) => chat.isGroup).toList();
        break;
    }

    if (searchController.text.isNotEmpty) {
      _filterChats(searchController.text, filtered);
    } else {
      filteredChats.assignAll(filtered);
    }

    print('🔍 Tab ${selectedTabIndex.value} filtered to ${filteredChats.length} chats');
  }

  void _filterChats(String query, [List<ChatModel>? chatsToFilter]) {
    final chats = chatsToFilter ?? _getCurrentTabChats();

    if (query.isEmpty) {
      filteredChats.assignAll(chats);
      return;
    }

    final queryLower = query.toLowerCase();
    filteredChats.assignAll(
      chats.where((chat) {
        return chat.name.toLowerCase().contains(queryLower) ||
            chat.lastMessage.toLowerCase().contains(queryLower);
      }).toList(),
    );
  }

  List<ChatModel> _getCurrentTabChats() {
    switch (selectedTabIndex.value) {
      case 0:
        return allChats;
      case 1:
        return allChats.where((chat) => !chat.isGroup).toList();
      case 2:
        return allChats.where((chat) => chat.isGroup).toList();
      default:
        return allChats;
    }
  }

  void onSearchChanged(String query) {
    _filterChats(query);
  }

  // ================================
  // 🔸 Helpers
  // ================================

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      return days[dateTime.weekday % 7];
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  // ================================
  // 🔸 Mark as Read
  // ================================

  Future<void> markChatAsRead(String chatId, bool isGroup) async {
    try {
      if (currentUserId.isEmpty) {
        print('❌ Cannot mark as read - user not logged in');
        return;
      }

      final collection = isGroup ? 'groups' : 'chat_rooms';
      await _firestore.collection(collection).doc(chatId).update({
        'unreadCount.$currentUserId': 0,
      });
      print('✅ Marked chat $chatId as read for user $currentUserId');
    } catch (e) {
      print('❌ Error marking chat as read: $e');
    }
  }

  // ================================
  // 🔸 Delete Chat
  // ================================

  Future<void> deleteChat(String chatId, bool isGroup) async {
    try {
      if (currentUserId.isEmpty) {
        AppSnackbar.error('يجب تسجيل الدخول أولاً');
        return;
      }

      if (isGroup) {
        await _firestore.collection('groups').doc(chatId).update({
          'participants': FieldValue.arrayRemove([currentUserId]),
        });
        print('✅ User $currentUserId removed from group $chatId');
      } else {
        await _firestore.collection('chat_rooms').doc(chatId).delete();
        print('✅ Private chat $chatId deleted');
      }

      allChats.removeWhere((chat) => chat.id == chatId);
      _applyTabFilter();

      AppSnackbar.success('تم حذف المحادثة بنجاح');

    } catch (e) {
      print('❌ Error deleting chat: $e');
      AppSnackbar.error('فشل حذف المحادثة: $e');
    }
  }

  // ================================
  // 🔸 Refresh & Utilities
  // ================================

  Future<void> refresh() async {
    print('🔄 Refreshing chats for user: $currentUserId');

    if (currentUserId.isEmpty) {
      await _initCurrentUser();
    }

    isLoading.value = true;

    _groupChatsSubscription?.cancel();
    _privateChatsSubscription?.cancel();

    _listenToChats();

    AppSnackbar.success('تم تحديث المحادثات');
  }

  Future<bool> checkUserLoggedIn() async {
    try {
      final isLoggedIn = _prefs.getUserLoggedIn();
      final hasUserId = _prefs.getUserId() != null && _prefs.getUserId()!.isNotEmpty;

      return isLoggedIn && hasUserId;
    } catch (e) {
      return false;
    }
  }

  Map<String, String?> getCurrentUserInfo() {
    return {
      'user_id': currentUserId,
      'user_name': currentUserName.value,
      'user_image': currentUserImageUrl.value,
    };
  }

  Future<void> resetUser() async {
    currentUserId = '';
    currentUserName.value = null;
    currentUserImageUrl.value = null;
    isUserLoggedIn.value = false;

    _groupChatsSubscription?.cancel();
    _privateChatsSubscription?.cancel();
    _userSubscription?.cancel();

    allChats.clear();
    filteredChats.clear();

    print('✅ User data reset');
  }

  Future<void> smartRefresh() async {
    print('🔄 Smart refresh initiated');

    if (!isUserLoggedIn.value) {
      _handleNoUser();
      return;
    }

    if (hasIndexError.value) {
      _listenToChats();
    } else {
      refresh();
    }
  }
}

// ================================
// 🔸 Chat Model
// ================================

class ChatModel {
  final String id;
  final String name;
  final String imageUrl;
  final String lastMessage;
  final String time;
  final bool isGroup;
  final int membersCount;
  final int unreadCount;
  final dynamic lastMessageTime;
  final String? otherUserId;

  ChatModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.lastMessage,
    required this.time,
    required this.isGroup,
    this.membersCount = 0,
    this.unreadCount = 0,
    this.lastMessageTime,
    this.otherUserId,
  });

  @override
  String toString() {
    return 'ChatModel{id: $id, name: $name, isGroup: $isGroup, members: $membersCount}';
  }
}