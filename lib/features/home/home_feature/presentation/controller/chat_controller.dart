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
  RxBool isLoading = false.obs;
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
  final RxList<ChatModel> privateChats = <ChatModel>[].obs;
  final RxList<ChatModel> groupChats = <ChatModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    print('🚀 ChatController initialized');

    _initController().then((_) {
      // ✅ دائماً نستمع للمحادثات حتى لو لم يكن هناك محادثات حالياً
      _listenToChats();
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
  // 🔸 تهيئة الكونترولر - معدّل
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
        print('👤 No user ID found - user might be logged out');
        isUserLoggedIn.value = false;
        // ✅ لا نمنع المستخدم من رؤية الواجهة، فقط نخبره أنه غير مسجل
        return;
      }

      print('✅ Current user ID: $currentUserId');
      isUserLoggedIn.value = true;
      _loadCurrentUserData(); // ✅ تمت إضافة هذه الدالة

    } catch (e) {
      print('❌ Error initializing current user: $e');
      isUserLoggedIn.value = false;
    }
  }

  // ================================
  // 🔸 دالة جديدة: تحميل بيانات المستخدم الحالي
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
  // 🔸 الاستماع للمحادثات - معدّل بالكامل
  // ================================

  void _listenToChats() {
    // ✅ دائماً نحاول جلب البيانات حتى لو لم يكن المستخدم مسجلاً
    // لأن المستخدم قد يكون مسجلاً ولكن ليس لديه محادثات

    isLoading.value = true;
    hasIndexError.value = false;

    print('👂 Listening to real-time chats for user: ${currentUserId.isEmpty ? 'unknown' : currentUserId}');

    // محاولة الاستماع للمجموعات
    _tryGroupsListener();

    // محاولة الاستماع للمحادثات الخاصة
    _tryPrivateChatsListener();

    // ✅ إذا لم يكن هناك مستخدم، نوقف التحميل بعد فترة
    if (!isUserLoggedIn.value) {
      Future.delayed(Duration(seconds: 2), () {
        isLoading.value = false;
      });
    }
  }

  void _tryGroupsListener() {
    if (currentUserId.isEmpty) {
      print('ℹ️ No user ID for groups - listening without filter');
      _groupChatsSubscription = _firestore
          .collection('groups')
          .orderBy('lastMessageTime', descending: true)
          .limit(10) // ✅ تحديد عدد لتجنب الأخطاء
          .snapshots()
          .listen(
            (snapshot) {
          print('📥 Real-time groups update: ${snapshot.docs.length} groups');
          hasIndexError.value = false;
          _updateGroupChats(snapshot.docs);
        },
        onError: (error) {
          print('❌ Error in groups listener: $error');
          _handleGroupsError(error); // ✅ تمت إضافة هذه الدالة
        },
      );
    } else {
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
  }

  void _tryPrivateChatsListener() {
    if (currentUserId.isEmpty) {
      print('ℹ️ No user ID for private chats - listening without filter');
      _privateChatsSubscription = _firestore
          .collection('chat_rooms')
          .orderBy('lastMessageTime', descending: true)
          .limit(10) // ✅ تحديد عدد لتجنب الأخطاء
          .snapshots()
          .listen(
            (snapshot) {
          print('📥 Real-time private chats update: ${snapshot.docs.length} chats');
          hasIndexError.value = false;
          _updatePrivateChats(snapshot.docs);
        },
        onError: (error) {
          print('❌ Error in private chats listener: $error');
          _handlePrivateChatsError(error); // ✅ تمت إضافة هذه الدالة
        },
      );
    } else {
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
  }

  // ================================
  // 🔸 دوال جديدة: معالجة الأخطاء
  // ================================

  void _handleGroupsError(dynamic error) {
    isLoading.value = false;
    hasIndexError.value = true;

    print('🔧 Groups error detected: $error');

    // ✅ محاولة استعلام أبسط
    _trySimpleGroupsQuery();
  }

  void _handlePrivateChatsError(dynamic error) {
    isLoading.value = false;
    hasIndexError.value = true;

    print('🔧 Private chats error detected: $error');

    // ✅ محاولة استعلام أبسط
    _trySimplePrivateChatsQuery();
  }

  void _handleIndexError(dynamic error, String collection) {
    isLoading.value = false;
    hasIndexError.value = true;

    final errorStr = error.toString();

    if (errorStr.contains('index') || errorStr.contains('FAILED_PRECONDITION')) {
      print('🔧 Index error detected for $collection');

      if (collection == 'groups') {
        _trySimpleGroupsQuery();
      } else {
        _trySimplePrivateChatsQuery();
      }
    }
  }

  void _trySimpleGroupsQuery() {
    print('🔄 Trying simple groups query');

    try {
      if (currentUserId.isEmpty) {
        _firestore
            .collection('groups')
            .limit(20)
            .get()
            .then((snapshot) {
          print('✅ Simple groups query successful: ${snapshot.docs.length} documents');
          _updateGroupChats(snapshot.docs);
        });
      } else {
        _firestore
            .collection('groups')
            .where('participants', arrayContains: currentUserId)
            .get()
            .then((snapshot) {
          print('✅ Simple groups query successful: ${snapshot.docs.length} documents');
          _updateGroupChats(snapshot.docs);
        });
      }
    } catch (e) {
      print('❌ Simple groups query also failed: $e');
      _handleNoChatsAvailable();
    }
  }

  void _trySimplePrivateChatsQuery() {
    print('🔄 Trying simple private chats query');

    try {
      if (currentUserId.isEmpty) {
        _firestore
            .collection('chat_rooms')
            .limit(20)
            .get()
            .then((snapshot) {
          print('✅ Simple private chats query successful: ${snapshot.docs.length} documents');
          _updatePrivateChats(snapshot.docs);
        });
      } else {
        _firestore
            .collection('chat_rooms')
            .where('participants', arrayContains: currentUserId)
            .get()
            .then((snapshot) {
          print('✅ Simple private chats query successful: ${snapshot.docs.length} documents');
          _updatePrivateChats(snapshot.docs);
        });
      }
    } catch (e) {
      print('❌ Simple private chats query also failed: $e');
      _handleNoChatsAvailable();
    }
  }

  void _handleNoChatsAvailable() {
    print('💬 No chats available for user ${currentUserId.isEmpty ? 'unknown' : currentUserId}');
    hasData.value = false;
    isLoading.value = false;

    // ✅ لا نعرض رسالة خطأ، فقط نوقف التحميل
  }

  void _updateGroupChats(List<QueryDocumentSnapshot> docs) {
    final groupChats = <ChatModel>[];

    for (var doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);

        // ✅ التحقق مما إذا كان المستخدم الحالي عضو في المجموعة
        final isUserInGroup = currentUserId.isEmpty ? false : participants.contains(currentUserId);

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
          isUserParticipant: isUserInGroup, // ✅ إضافة هذا الحقل
        );

        groupChats.add(chat);
      } catch (e) {
        print('❌ Error parsing group ${doc.id}: $e');
      }
    }

    _updateChatsList(groupChats, true);
    print('✅ Updated ${groupChats.length} groups');
  }

  void _updatePrivateChats(List<QueryDocumentSnapshot> docs) {
    final privateChats = <ChatModel>[];

    for (var doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);

        // ✅ التحقق مما إذا كان المستخدم الحالي عضو في المحادثة
        final isUserInChat = currentUserId.isEmpty ? false : participants.contains(currentUserId);

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
          isUserParticipant: isUserInChat, // ✅ إضافة هذا الحقل
        );

        privateChats.add(chat);
      } catch (e) {
        print('❌ Error parsing private chat ${doc.id}: $e');
      }
    }

    _updateChatsList(privateChats, false);
    print('✅ Updated ${privateChats.length} private chats');
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
    if (unreadData == null || currentUserId.isEmpty) return 0;

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
  // 🔸 Sorting & Filtering - معدّل
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

    // ✅ تصفية حسب مشاركة المستخدم إذا كان مسجلاً
    if (isUserLoggedIn.value) {
      filtered = filtered.where((chat) => chat.isUserParticipant).toList();
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
    List<ChatModel> chats;
    switch (selectedTabIndex.value) {
      case 0:
        chats = allChats;
        break;
      case 1:
        chats = allChats.where((chat) => !chat.isGroup).toList();
        break;
      case 2:
        chats = allChats.where((chat) => chat.isGroup).toList();
        break;
      default:
        chats = allChats;
    }

    // ✅ تصفية حسب مشاركة المستخدم إذا كان مسجلاً
    if (isUserLoggedIn.value) {
      chats = chats.where((chat) => chat.isUserParticipant).toList();
    }

    return chats;
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
  // 🔸 Mark as Read - معدّل
  // ================================

  Future<void> markChatAsRead(String chatId, bool isGroup) async {
    try {
      if (currentUserId.isEmpty) {
        print('ℹ️ Cannot mark as read - user not logged in');
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
  // 🔸 Delete Chat - معدّل
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
  // 🔸 Refresh & Utilities - معدّل
  // ================================

  Future<void> refresh() async {
    print('🔄 Refreshing chats for user: ${currentUserId.isEmpty ? 'unknown' : currentUserId}');

    isLoading.value = true;

    _groupChatsSubscription?.cancel();
    _privateChatsSubscription?.cancel();

    _listenToChats();

    AppSnackbar.success('تم تحديث المحادثات');
  }

  // Future<bool> checkUserLoggedIn() async {
  //   try {
  //     if (_prefs == null) {
  //       print('❌ _prefs is not initialized');
  //       return false;
  //     }
  //
  //     // ✅ التحقق من AppSettingsPrefs أولاً
  //     final isLoggedIn = _prefs!.getUserLoggedIn();
  //     final userId = _prefs!.getUserId();
  //     final hasValidUserId = userId != null && userId.isNotEmpty;
  //
  //     if (isLoggedIn && hasValidUserId) {
  //       print('✅ User is logged in with ID: $userId');
  //       currentUserId = userId;
  //       currentUserName.value = _prefs!.getUserName() ?? 'مستخدم';
  //       return true;
  //     }
  //
  //     // ✅ البحث في SharedPreferences مباشرة
  //     final sharedPrefs = await SharedPreferences.getInstance();
  //     final alternativeUserId = sharedPrefs.getString('user_id') ??
  //         sharedPrefs.getString('userId');
  //
  //     if (alternativeUserId != null && alternativeUserId.isNotEmpty) {
  //       print('✅ Found user in alternative storage: $alternativeUserId');
  //
  //       // ✅ استخدام الدوال الفردية بدلاً من cacheUserData
  //       await _cacheUserDataManually(
  //         userId: alternativeUserId,
  //         name: sharedPrefs.getString('user_name') ?? 'مستخدم',
  //         phone: sharedPrefs.getString('phone') ?? '',
  //       );
  //
  //       currentUserId = alternativeUserId;
  //       currentUserName.value = sharedPrefs.getString('user_name') ?? 'مستخدم';
  //       currentUserImageUrl.value = sharedPrefs.getString('user_image') ?? '';
  //
  //       return true;
  //     }
  //
  //     print('❌ No logged in user found');
  //     return false;
  //
  //   } catch (e) {
  //     print('❌ Error in checkUserLoggedIn: $e');
  //     return false;
  //   }
  // }
  Future<bool> checkUserLoggedIn() async {
    try {
      if (_prefs == null) return false;

      // المحاولة الأولى: من AppSettingsPrefs
      if (_prefs!.getUserLoggedIn()) {
        final userId = _prefs!.getUserId();
        if (userId != null && userId.isNotEmpty) {
          currentUserId = userId;
          currentUserName.value = _prefs!.getUserName() ?? 'مستخدم';
          print('✅ User logged in: $userId');
          return true;
        }
      }

      // المحاولة الثانية: من SharedPreferences مباشرة
      final sharedPrefs = await SharedPreferences.getInstance();
      final userId = sharedPrefs.getString('user_id') ??
          sharedPrefs.getString('userId');

      if (userId != null && userId.isNotEmpty) {
        // تحديث AppSettingsPrefs
        _prefs.setUserLoggedIn();
        _prefs.setUserId(userId);

        currentUserId = userId;
        currentUserName.value = sharedPrefs.getString('user_name') ?? 'مستخدم';

        print('✅ User found in shared prefs: $userId');
        return true;
      }

      return false;

    } catch (e) {
      print('❌ Error in checkUserLoggedIn: $e');
      return false;
    }
  }

  Map<String, String?> getCurrentUserInfo() {
    return {
      'user_id': currentUserId.isNotEmpty ? currentUserId : null,
      'user_name': currentUserName.value!.isNotEmpty ? currentUserName.value : null,
      'user_image': currentUserImageUrl.value!.isNotEmpty ? currentUserImageUrl.value : null,
    };
  }
// ✅ دالة مساعدة بديلة لـ cacheUserData
  Future<void> _cacheUserDataManually({
    required String userId,
    required String name,
    required String phone,
  }) async {
    try {
      _prefs.setUserLoggedIn();
      _prefs.setUserId(userId);
      _prefs.setUserName(name);
      _prefs.setUserPhone(phone);

      // تأكيد الحفظ
      final sharedPrefs = await SharedPreferences.getInstance();
      await sharedPrefs.reload();

      print('✅ User data cached manually: $userId');
    } catch (e) {
      print('❌ Error in _cacheUserDataManually: $e');
    }
  }
  // Map<String, String?> getCurrentUserInfo() {
  //   return {
  //     'user_id': currentUserId,
  //     'user_name': currentUserName.value,
  //     'user_image': currentUserImageUrl.value,
  //   };
  // }

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

    if (hasIndexError.value) {
      _listenToChats();
    } else {
      refresh();
    }
  }

  // ================================
  // 🔸 دالة جديدة: تحديث حالة المستخدم
  // ================================

  Future<void> updateUserStatus() async {
    await _initCurrentUser();
    _listenToChats(); // إعادة تحميل المحادثات مع الفلتر الجديد
  }
}

// ================================
// 🔸 Chat Model - معدّل
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
  final bool isUserParticipant; // ✅ حقل جديد

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
    this.isUserParticipant = true, // ✅ قيمة افتراضية
  });

  @override
  String toString() {
    return 'ChatModel{id: $id, name: $name, isGroup: $isGroup, isUserParticipant: $isUserParticipant}';
  }
}