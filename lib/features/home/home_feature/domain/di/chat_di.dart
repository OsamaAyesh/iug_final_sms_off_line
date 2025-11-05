import '../../data/data_source/chat_remote_data_source.dart';
import '../../data/repository/chat_repository_impl.dart';
import '../use_cases/get_chat_rooms_use_case.dart';

class ChatDI {
  late final ChatRemoteDataSource _remote;
  late final ChatRepositoryImpl _repository;
  late final GetChatRoomsUseCase getChatRoomsUseCase;

  ChatDI() {
    _remote = ChatRemoteDataSource();
    _repository = ChatRepositoryImpl(remote: _remote);
    getChatRoomsUseCase = GetChatRoomsUseCase(_repository);
  }
}
