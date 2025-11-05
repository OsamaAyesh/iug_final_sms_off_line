import '../models/chat_room_model.dart';
import '../../data/repository/chat_repository_impl.dart';

class GetChatRoomsUseCase {
  final ChatRepositoryImpl _repository;
  GetChatRoomsUseCase(this._repository);

  Future<List<ChatRoomModel>> executeAll() async {
    return await _repository.getAllChats();
  }

  Future<List<ChatRoomModel>> executeGroups() async {
    return await _repository.getGroupChats();
  }

  Future<List<ChatRoomModel>> executePrivate() async {
    return await _repository.getPrivateChats();
  }
}
