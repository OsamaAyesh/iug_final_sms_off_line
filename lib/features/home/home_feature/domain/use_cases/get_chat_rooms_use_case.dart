import '../models/chat_room_model.dart';
import '../../data/repository/chat_repository_impl.dart';

class GetChatRoomsUseCase {
  final ChatRepositoryImpl _repository;
  GetChatRoomsUseCase(this._repository);

  Future<List<ChatRoomModel>> executeAll() async {
    final chats = await _repository.getAllChats();
    print('🎯 UseCase: Returning ${chats.length} chats for current user');
    return chats;
  }

  Future<List<ChatRoomModel>> executeGroups() async {
    final groups = await _repository.getGroupChats();
    print('🎯 UseCase: Returning ${groups.length} groups for current user');
    return groups;
  }

  Future<List<ChatRoomModel>> executePrivate() async {
    final privateChats = await _repository.getPrivateChats();
    print('🎯 UseCase: Returning ${privateChats.length} private chats for current user');
    return privateChats;
  }
}