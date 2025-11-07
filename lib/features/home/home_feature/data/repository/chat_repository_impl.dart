import '../../domain/models/chat_room_model.dart';
import '../data_source/chat_remote_data_source.dart';

class ChatRepositoryImpl {
  final ChatRemoteDataSource remote;
  ChatRepositoryImpl({required this.remote});

  Future<List<ChatRoomModel>> getAllChats() async {
    try {
      return await remote.getAllChats();
    } catch (e) {
      print('❌ Repository Error in getAllChats: $e');
      return [];
    }
  }

  Future<List<ChatRoomModel>> getPrivateChats() async {
    try {
      return await remote.getPrivateChats();
    } catch (e) {
      print('❌ Repository Error in getPrivateChats: $e');
      return [];
    }
  }

  Future<List<ChatRoomModel>> getGroupChats() async {
    try {
      return await remote.getGroupChats();
    } catch (e) {
      print('❌ Repository Error in getGroupChats: $e');
      return [];
    }
  }
}