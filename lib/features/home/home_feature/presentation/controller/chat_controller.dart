// المسار: lib/features/home/home_feature/presentation/controller/chat_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatController extends GetxController {
  static ChatController get to => Get.find<ChatController>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers
  final searchController = TextEditingController();

  // States
  final isLoading = false.obs;
  final selectedTabIndex = 0.obs;

  // Data
  final allChats = <ChatModel>[].obs;
  final filteredChats = <ChatModel>[].obs;

  // Current User
  String get currentUserId => _auth.currentUser?.uid ?? '567450057';
  final currentUserImageUrl = Rxn<String>();
  final currentUserName = Rxn<String>();

  // Streams
  StreamSubscription? _groupChatsSubscription;
  StreamSubscription? _userSubscription;

  @override
  void onInit() {
    super.onInit();
    print('🚀 ChatController initialized - User: $currentUserId');
    _loadCurrentUser();
    _listenToChats();

    searchController.addListener(() {
      _filterChats(searchController.text);
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    _groupChatsSubscription?.cancel();
    _userSubscription?.cancel();
    super.onClose();
  }

  // ================================
  // 🔸 Load Current User
  // ================================

  Future<void> _loadCurrentUser() async {
    try {
      print('👤 Loading current user: $currentUserId');

      _userSubscription = _firestore
          .collection('users')
          .doc(currentUserId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          currentUserImageUrl.value = data?['imageUrl'];
          currentUserName.value = data?['name'];
          print('✅ User loaded: ${currentUserName.value}');
        }
      });
    } catch (e) {
      print('❌ Error loading user: $e');
    }
  }

  // ================================
  // 🔸 Real-time Chat Listeners
  // ================================

  void _listenToChats() {
    isLoading.value = true;
    print('👂 Listening to chats for user: $currentUserId');

    // Listen to Group Chats with Real-time updates
    _groupChatsSubscription = _firestore
        .collection('groups')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .listen(
          (snapshot) {
        print('📥 Received ${snapshot.docs.length} groups');
        _updateGroupChats(snapshot.docs);
      },
      onError: (error) {
        print('❌ Error listening to groups: $error');
        isLoading.value = false;
      },
    );
  }

  void _updateGroupChats(List<QueryDocumentSnapshot> docs) {
    final groupChats = <ChatModel>[];

    for (var doc in docs) {
      try {
        final data = doc.data() as Map<String, dynamic>;

        final chat = ChatModel(
          id: doc.id,
          name: data['name'] ?? 'Unknown Group',
          imageUrl: data['imageUrl'] ?? '',
          lastMessage: data['lastMessage'] ?? '',
          time: _formatTime(data['lastMessageTime']),
          isGroup: true,
          membersCount: (data['participants'] as List?)?.length ?? 0,
          unreadCount: _calculateUnreadCount(data['unreadCount']),
          lastMessageTime: data['lastMessageTime'],
        );

        groupChats.add(chat);
      } catch (e) {
        print('❌ Error parsing group ${doc.id}: $e');
      }
    }

    // Update all chats
    allChats.assignAll(groupChats);

    // Sort by last message time
    _sortChats();
    _applyTabFilter();

    isLoading.value = false;
    print('✅ Updated ${groupChats.length} chats');
  }

  int _calculateUnreadCount(dynamic unreadData) {
    if (unreadData == null) return 0;

    try {
      final unreadMap = Map<String, dynamic>.from(unreadData);
      final count = unreadMap[currentUserId];
      return count is int ? count : 0;
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
      return b.lastMessageTime!.compareTo(a.lastMessageTime!);
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
      const days = [
        'الأحد',
        'الاثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت'
      ];
      return days[dateTime.weekday % 7];
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  // ================================
  // 🔸 Mark as Read
  // ================================

  Future<void> markChatAsRead(String chatId, bool isGroup) async {
    try {
      final collection = isGroup ? 'groups' : 'chats';
      await _firestore.collection(collection).doc(chatId).update({
        'unreadCount.$currentUserId': 0,
      });
      print('✅ Marked chat $chatId as read');
    } catch (e) {
      print('❌ Error marking chat as read: $e');
    }
  }

  // ================================
  // 🔸 Delete Chat
  // ================================

  Future<void> deleteChat(String chatId, bool isGroup) async {
    try {
      if (isGroup) {
        await _firestore.collection('groups').doc(chatId).update({
          'participants': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        await _firestore.collection('chats').doc(chatId).delete();
      }

      Get.snackbar(
        'نجح',
        'تم حذف المحادثة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      print('✅ Deleted chat $chatId');
    } catch (e) {
      print('❌ Error deleting chat: $e');
      Get.snackbar(
        'خطأ',
        'فشل حذف المحادثة: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ================================
  // 🔸 Refresh
  // ================================

  Future<void> refresh() async {
    print('🔄 Refreshing chats...');
    // Streams will auto-update, no manual refresh needed
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
  final Timestamp? lastMessageTime;
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
}