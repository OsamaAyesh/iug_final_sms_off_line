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
  final isInitialLoading = true.obs;
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
    _initController().then((_) {
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

  // ============================
  // 🔸 Initialization
  // ============================
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
        isUserLoggedIn.value = false;
        return;
      }
      isUserLoggedIn.value = true;
      _loadCurrentUserData();
    } catch (e) {
      isUserLoggedIn.value = false;
    }
  }

  Future<void> _loadCurrentUserData() async {
    try {
      _userSubscription = _firestore
          .collection('users')
          .doc(currentUserId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          currentUserImageUrl.value = data?['imageUrl'];
          currentUserName.value = data?['name'];
        }
      });
    } catch (e) {
      print('❌ Error in _loadCurrentUserData: $e');
    }
  }

  // ============================
  // 🔸 Listening to Chats
  // ============================
  void _listenToChats() {
    isInitialLoading.value = true;
    isLoading.value = true;
    hasIndexError.value = false;

    _tryGroupsListener();
    _tryPrivateChatsListener();

    if (!isUserLoggedIn.value) {
      Future.delayed(const Duration(seconds: 2), () {
        isLoading.value = false;
        isInitialLoading.value = false;
      });
    }
  }

  void _tryGroupsListener() {
    final query = currentUserId.isEmpty
        ? _firestore.collection('groups').orderBy('lastMessageTime', descending: true).limit(10)
        : _firestore
        .collection('groups')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true);

    _groupChatsSubscription = query.snapshots().listen((snapshot) {
      _updateGroupChats(snapshot.docs);
    }, onError: (error) {
      _handleIndexError(error, 'groups');
    });
  }

  // void _tryPrivateChatsListener() {
  //   final query = currentUserId.isEmpty
  //       ? _firestore.collection('chats').orderBy('lastMessageTime', descending: true).limit(10)
  //       : _firestore
  //       .collection('chats')
  //       .where('participants', arrayContains: currentUserId)
  //       .orderBy('lastMessageTime', descending: true);
  //
  //   _privateChatsSubscription = query.snapshots().listen((snapshot) {
  //     _updatePrivateChats(snapshot.docs);
  //   }, onError: (error) {
  //     _handleIndexError(error, 'chats');
  //   });
  // }
  void _tryPrivateChatsListener() {
    print('🟢 [_tryPrivateChatsListener] STARTED for user: $currentUserId');

    final query = currentUserId.isEmpty
        ? _firestore.collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .limit(10)
        : _firestore.collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .limit(20);

    _privateChatsSubscription = query.snapshots().listen((snapshot) {
      print('📥 [Listener] Received ${snapshot.docs.length} private chat docs');
      _updatePrivateChats(snapshot.docs);
    }, onError: (error) {
      print('❌ [Listener Error] $error');
      _handleIndexError(error, 'chats');
      print('🛑 Cancelling listener due to index error...');
      _privateChatsSubscription?.cancel();
      _trySimplePrivateChatsQuery();
    });
  }
  void _trySimplePrivateChatsQuery() {
    print('🟠 [_trySimplePrivateChatsQuery] Running simple query for user: $currentUserId');

    final simpleQuery = currentUserId.isEmpty
        ? _firestore.collection('chats').limit(20)
        : _firestore.collection('chats')
        .where('participants', arrayContains: currentUserId)
        .limit(20);

    simpleQuery.get().then((snapshot) {
      print('📄 [SimpleQuery] Found ${snapshot.docs.length} docs');
      _updatePrivateChats(snapshot.docs);
    }).catchError((error) {
      print('❌ [SimpleQuery Error] $error');
    });
  }
  void _handleIndexError(dynamic error, String collection) {
    isLoading.value = false;
    hasIndexError.value = true;
  }

  // ============================
  // 🔸 Update Data
  // ============================
  void _updateGroupChats(List<QueryDocumentSnapshot> docs) {
    final groupChats = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return ChatModel(
        id: doc.id,
        name: data['name'] ?? 'مجموعة بدون اسم',
        imageUrl: data['imageUrl'] ?? '',
        lastMessage: data['lastMessage'] ?? 'لا توجد رسائل',
        time: _formatTime(data['lastMessageTime']),
        isGroup: true,
        membersCount: (data['participants'] as List?)?.length ?? 0,
        unreadCount: _calculateUnreadCount(data['unreadCount']),
        lastMessageTime: data['lastMessageTime'],
        isUserParticipant: currentUserId.isNotEmpty &&
            (data['participants'] as List?)?.contains(currentUserId) == true,
      );
    }).toList();

    _updateChatsList(groupChats, true);
  }

  // void _updatePrivateChats(List<QueryDocumentSnapshot> docs) {
  //   final privateChats = docs.map((doc) {
  //     final data = doc.data() as Map<String, dynamic>;
  //     return ChatModel(
  //       id: doc.id,
  //       name: data['name'] ?? 'محادثة خاصة',
  //       imageUrl: data['imageUrl'] ?? '',
  //       lastMessage: data['lastMessage'] ?? 'لا توجد رسائل',
  //       time: _formatTime(data['lastMessageTime']),
  //       isGroup: false,
  //       membersCount: (data['participants'] as List?)?.length ?? 0,
  //       unreadCount: _calculateUnreadCount(data['unreadCount']),
  //       lastMessageTime: data['lastMessageTime'],
  //       isUserParticipant: currentUserId.isNotEmpty &&
  //           (data['participants'] as List?)?.contains(currentUserId) == true,
  //     );
  //   }).toList();
  //
  //   _updateChatsList(privateChats, false);
  // }
  void _updatePrivateChats(List<QueryDocumentSnapshot> docs) async {
    print('🔵 [_updatePrivateChats] Called with ${docs.length} documents');
    final List<ChatModel> privateChats = [];

    for (var doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;
        final List participants = List.from(data['participants'] ?? []);
        final chatId = doc.id;

        print('  ▶ Processing chat: $chatId with participants: $participants');

        if (participants.length < 2) continue;
        final otherUserId = participants.firstWhere(
              (id) => id != currentUserId,
          orElse: () => null,
        );
        if (otherUserId == null) continue;

        final otherUserSnapshot = await _firestore.collection('users').doc(otherUserId).get();
        final otherUserName = otherUserSnapshot.data()?['name'] ?? 'مستخدم';
        final otherUserImage = otherUserSnapshot.data()?['imageUrl'] ?? '';

        print('    ✅ Other user resolved: $otherUserName ($otherUserId)');

        final chat = ChatModel(
          id: chatId,
          name: otherUserName,
          imageUrl: otherUserImage,
          lastMessage: data['lastMessage'] ?? 'لا توجد رسائل',
          time: _formatTime(data['lastMessageTime']),
          isGroup: false,
          membersCount: participants.length,
          unreadCount: _calculateUnreadCount(data['unreadCount']),
          lastMessageTime: data['lastMessageTime'],
          isUserParticipant: participants.contains(currentUserId),
        );

        if (!privateChats.any((c) => c.id == chat.id)) {
          privateChats.add(chat);
        } else {
          print('    ⚠️ Duplicate detected for chatId: $chatId (ignored)');
        }
      } catch (e) {
        print('❌ Error parsing chat doc: $e');
      }
    }

    print('🧮 [_updatePrivateChats] Total unique chats: ${privateChats.length}');
    _updateChatsList(privateChats, false);
  }

  void _updateChatsList(List<ChatModel> newChats, bool areGroups) {
    final otherChats = allChats.where((chat) => chat.isGroup != areGroups).toList();
    allChats.assignAll([...newChats, ...otherChats]);
    _sortChats();
    _applyTabFilter();
    allChats.assignAll(allChats.toSet().toList());

    isLoading.value = false;
    isInitialLoading.value = false;
    hasData.value = allChats.isNotEmpty;
  }

  // ✅ إضافة الدالة المفقودة
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

  // ============================
  // 🔸 Filters & Search
  // ============================
  void changeTab(int index) {
    selectedTabIndex.value = index;
    _applyTabFilter();
  }

  void _applyTabFilter() {
    List<ChatModel> filtered = [];
    switch (selectedTabIndex.value) {
      case 0:
        filtered = allChats;
        break;
      case 1:
        filtered = allChats.where((chat) => !chat.isGroup).toList();
        break;
      case 2:
        filtered = allChats.where((chat) => chat.isGroup).toList();
        break;
    }

    if (searchController.text.isNotEmpty) {
      _filterChats(searchController.text, filtered);
    } else {
      filteredChats.assignAll(filtered);
    }
  }

  void _filterChats(String query, [List<ChatModel>? source]) {
    final chats = source ?? allChats;
    if (query.isEmpty) {
      filteredChats.assignAll(chats);
      return;
    }
    final q = query.toLowerCase();
    filteredChats.assignAll(
      chats.where((chat) {
        return chat.name.toLowerCase().contains(q) ||
            chat.lastMessage.toLowerCase().contains(q);
      }).toList(),
    );
  }

  void onSearchChanged(String query) {
    _filterChats(query);
  }

  // ============================
  // 🔸 Helpers
  // ============================
  int _calculateUnreadCount(dynamic unreadData) {
    if (unreadData == null || currentUserId.isEmpty) return 0;
    if (unreadData is Map<String, dynamic>) {
      final count = unreadData[currentUserId];
      return count is int ? count : 0;
    }
    return 0;
  }

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
    final diff = now.difference(dateTime);
    if (diff.inDays == 0) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      return days[dateTime.weekday % 7];
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  // ============================
  // 🔸 Authentication
  // ============================
  Future<bool> checkUserLoggedIn() async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final userId = sharedPrefs.getString('user_id') ?? sharedPrefs.getString('userId');
      if (userId != null && userId.isNotEmpty) {
        _prefs.setUserId(userId);
        currentUserId = userId;
        isUserLoggedIn.value = true;
        return true;
      }
      isUserLoggedIn.value = false;
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================
  // 🔸 Chat Actions
  // ============================
  Future<void> markChatAsRead(String chatId, bool isGroup) async {
    try {
      if (currentUserId.isEmpty) return;
      final collection = isGroup ? 'groups' : 'chats';
      await _firestore.collection(collection).doc(chatId).update({
        'unreadCount.$currentUserId': 0,
      });
    } catch (_) {}
  }

  Future<void> deleteChat(String chatId, bool isGroup) async {
    try {
      if (currentUserId.isEmpty) return;
      if (isGroup) {
        await _firestore.collection('groups').doc(chatId).update({
          'participants': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        await _firestore.collection('chats').doc(chatId).delete();
      }
      allChats.removeWhere((c) => c.id == chatId);
      _applyTabFilter();
      AppSnackbar.success('تم حذف المحادثة');
    } catch (e) {
      AppSnackbar.error('فشل حذف المحادثة: $e');
    }
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
  }

  Future<void> smartRefresh() async {
    isInitialLoading.value = true;
    isLoading.value = true;
    _groupChatsSubscription?.cancel();
    _privateChatsSubscription?.cancel();
    _listenToChats();
    AppSnackbar.success('تم التحديث');
  }
}

// ============================
// 🔸 Chat Model
// ============================
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
  final bool isUserParticipant;

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
    this.isUserParticipant = true,
  });
}

