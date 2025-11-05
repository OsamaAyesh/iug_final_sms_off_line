import '../../domain/models/chat_room_model.dart';
import '../data_source/chat_remote_data_source.dart';

class ChatRepositoryImpl {
  final ChatRemoteDataSource remote;
  ChatRepositoryImpl({required this.remote});

  Future<List<ChatRoomModel>> getAllChats() async {
    return await remote.getAllChats();
  }

  Future<List<ChatRoomModel>> getPrivateChats() async {
    return await remote.getPrivateChats();
  }

  Future<List<ChatRoomModel>> getGroupChats() async {
    return await remote.getGroupChats();
  }
}
