import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_mobile/core/storage/local/app_settings_prefs.dart'; // 🔹 أضف هذا
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/chat_room_model.dart';
import '../mapper/chat_mapper.dart';
import '../response/chat_room_response.dart';

class ChatRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AppSettingsPrefs _prefs; // 🔹 نظام التسجيل الخاص

  // 🔹 تهيئة Prefs
  ChatRemoteDataSource() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    _prefs = AppSettingsPrefs(sharedPrefs);
  }

  // 🔹 جلب user_id الحالي
  Future<String?> _getCurrentUserId() async {
    try {
      await _initPrefs(); // تأكد من تهيئة Prefs
      return _prefs.getUserId();
    } catch (e) {
      print('❌ Error getting current user ID: $e');
      return null;
    }
  }

  /// 🔹 جلب المحادثات الخاصة للمستخدم الحالي فقط
  Future<List<ChatRoomModel>> getPrivateChats() async {
    final currentUserId = await _getCurrentUserId();

    if (currentUserId == null || currentUserId.isEmpty) {
      print('❌ No user ID found for private chats');
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: currentUserId) // 🔹 التصفية هنا
          .orderBy('timestamp', descending: true)
          .get();

      print('✅ Found ${snapshot.docs.length} private chats for user: $currentUserId');

      return snapshot.docs
          .map((doc) =>
          ChatRoomResponse.fromJson(doc.data()).toDomain(doc.id, false))
          .toList();
    } catch (e) {
      print('❌ Error fetching private chats: $e');
      return [];
    }
  }

  /// 🔹 جلب المجموعات للمستخدم الحالي فقط
  Future<List<ChatRoomModel>> getGroupChats() async {
    final currentUserId = await _getCurrentUserId();

    if (currentUserId == null || currentUserId.isEmpty) {
      print('❌ No user ID found for group chats');
      return [];
    }

    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('participants', arrayContains: currentUserId) // 🔹 التصفية هنا
          .orderBy('lastMessageTime', descending: true)
          .get();

      print('✅ Found ${snapshot.docs.length} groups for user: $currentUserId');

      return snapshot.docs
          .map((doc) =>
          ChatRoomResponse.fromJson(doc.data()).toDomain(doc.id, true))
          .toList();
    } catch (e) {
      print('❌ Error fetching group chats: $e');
      return [];
    }
  }

  /// 🔹 جلب جميع المحادثات (مدمج) للمستخدم الحالي فقط
  Future<List<ChatRoomModel>> getAllChats() async {
    final currentUserId = await _getCurrentUserId();

    if (currentUserId == null || currentUserId.isEmpty) {
      print('❌ No user ID found for all chats');
      return [];
    }

    try {
      final privateChats = await getPrivateChats();
      final groupChats = await getGroupChats();

      final allChats = [...groupChats, ...privateChats];
      print('✅ Total chats for user $currentUserId: ${allChats.length}');

      return allChats;
    } catch (e) {
      print('❌ Error fetching all chats: $e');
      return [];
    }
  }
}