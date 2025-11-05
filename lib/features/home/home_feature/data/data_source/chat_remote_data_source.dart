import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/chat_room_model.dart';
import '../mapper/chat_mapper.dart';
import '../response/chat_room_response.dart';

class ChatRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all private chat rooms
  Future<List<ChatRoomModel>> getPrivateChats() async {
    final snapshot = await _firestore
        .collection('chat_rooms')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs
        .map((doc) =>
        ChatRoomResponse.fromJson(doc.data()).toDomain(doc.id, false))
        .toList();
  }

  /// Fetch all group chats
  Future<List<ChatRoomModel>> getGroupChats() async {
    final snapshot = await _firestore
        .collection('groups')
        .orderBy('lastMessageTime', descending: true)
        .get();

    return snapshot.docs
        .map((doc) =>
        ChatRoomResponse.fromJson(doc.data()).toDomain(doc.id, true))
        .toList();
  }

  /// Fetch all (merged)
  Future<List<ChatRoomModel>> getAllChats() async {
    final chats = await getPrivateChats();
    final groups = await getGroupChats();
    return [...groups, ...chats];
  }
}
