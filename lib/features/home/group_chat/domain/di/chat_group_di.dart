import '../../data/data_source/chat_group_remote_data_source.dart';
import '../../data/repository/chat_group_repository.dart';
import '../../domain/models/message_model.dart';
import '../../data/request/send_message_request.dart';

class ChatGroupRepositoryImpl implements ChatGroupRepository {
  final ChatGroupRemoteDataSource remote;

  ChatGroupRepositoryImpl(this.remote);

  @override
  Stream<List<MessageModel>> getMessages(String groupId) {
    return remote.getMessages(groupId);
  }

  @override
  Future<void> sendMessage(SendMessageRequest request) {
    return remote.sendMessage(request);
  }

  @override
  Future<void> updateMessageStatus(String groupId, String messageId, Map<String, dynamic> status) {
    return remote.updateMessageStatus(groupId, messageId, status);
  }

  @override
  Future<void> sendSmsToUsers(List<String> numbers, String text) {
    return remote.sendSmsToUsers(numbers, text);
  }
}
