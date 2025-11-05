// المسار: lib/features/home/chat/presentation/controller/chat_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatController extends GetxController {
  static ChatController get to => Get.find<ChatController>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers
  final searchController = TextEditingController();

  // States
  final isLoading = false.obs;
  final selectedTabIndex = 0.obs;

  // Data
  final allChats = <ChatModel>[].obs;
  final filteredChats = <ChatModel>[].obs;

  // Current User
  String currentUserId = '567450057'; // استبدل بـ FirebaseAuth.instance.currentUser!.uid
  final currentUserImageUrl = Rxn<String>();

  // Streams
  StreamSubscription? _privateChatsSubscription;
  StreamSubscription? _groupChatsSubscription;
  StreamSubscription? _userSubscription;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUser();
    _listenToChats();

    // Search listener
    searchController.addListener(() {
      _filterChats(searchController.text);
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    _privateChatsSubscription?.cancel();
    _groupChatsSubscription?.cancel();
    _userSubscription?.cancel();
    super.onClose();
  }

  // ================================
  // 🔸 Load Current User
  // ================================

  Future<void> _loadCurrentUser() async {
    try {
      _userSubscription = _firestore
          .collection('users')
          .doc(currentUserId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          currentUserImageUrl.value = snapshot.data()?['imageUrl'];
        }
      });
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  // ================================
  // 🔸 Real-time Chat Listeners
  // ================================

  void _listenToChats() {
    isLoading.value = true;

    // Listen to Private Chats
    _privateChatsSubscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .where('isGroup', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      _updatePrivateChats(snapshot.docs);
    });

    // Listen to Group Chats
    _groupChatsSubscription = _firestore
        .collection('groups')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .listen((snapshot) {
      _updateGroupChats(snapshot.docs);
    });
  }

  void _updatePrivateChats(List<QueryDocumentSnapshot> docs) {
    final privateChats = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // Get other user info
      final participants = List<String>.from(data['participants'] ?? []);
      final otherUserId = participants.firstWhere(
            (id) => id != currentUserId,
        orElse: () => '',
      );

      return ChatModel(
        id: doc.id,
        name: data['otherUserName'] ?? 'Unknown',
        imageUrl: data['otherUserImage'] ?? '',
        lastMessage: data['lastMessage'] ?? '',
        time: _formatTime(data['lastMessageTime']),
        isGroup: false,
        unreadCount: (data['unreadCount'] as Map?)?[currentUserId] ?? 0,
        lastMessageTime: data['lastMessageTime'],
        otherUserId: otherUserId,
      );
    }).toList();

    // Remove old private chats and add new ones
    allChats.removeWhere((chat) => !chat.isGroup);
    allChats.addAll(privateChats);

    // Sort by last message time
    _sortChats();
    _applyTabFilter();

    isLoading.value = false;
  }

  void _updateGroupChats(List<QueryDocumentSnapshot> docs) {
    final groupChats = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return ChatModel(
        id: doc.id,
        name: data['name'] ?? 'Unknown Group',
        imageUrl: data['imageUrl'] ?? '',
        lastMessage: data['lastMessage'] ?? '',
        time: _formatTime(data['lastMessageTime']),
        isGroup: true,
        membersCount: (data['participants'] as List?)?.length ?? 0,
        unreadCount: (data['unreadCount'] as Map?)?[currentUserId] ?? 0,
        lastMessageTime: data['lastMessageTime'],
      );
    }).toList();

    // Remove old group chats and add new ones
    allChats.removeWhere((chat) => chat.isGroup);
    allChats.addAll(groupChats);

    // Sort by last message time
    _sortChats();
    _applyTabFilter();

    isLoading.value = false;
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

    // Apply search filter
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
      // اليوم - عرض الوقت
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      // أمس
      return 'أمس';
    } else if (difference.inDays < 7) {
      // خلال الأسبوع - عرض اسم اليوم
      const days = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      return days[dateTime.weekday % 7];
    } else {
      // أكثر من أسبوع - عرض التاريخ
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
    } catch (e) {
      print('Error marking chat as read: $e');
    }
  }

  // ================================
  // 🔸 Delete Chat
  // ================================

  Future<void> deleteChat(String chatId, bool isGroup) async {
    try {
      if (isGroup) {
        // Remove user from group
        await _firestore.collection('groups').doc(chatId).update({
          'participants': FieldValue.arrayRemove([currentUserId]),
        });
      } else {
        // Delete private chat
        await _firestore.collection('chats').doc(chatId).delete();
      }

      Get.snackbar(
        'نجح',
        'تم حذف المحادثة',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل حذف المحادثة: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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