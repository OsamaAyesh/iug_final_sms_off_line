import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';

import '../data_source/chat_group_remote_data_source.dart';
import '../mapper/message_mapper.dart';
import '../request/send_message_request.dart';
import 'chat_group_repository.dart';

class ChatGroupRepositoryImpl extends ChatGroupRepository {
  final ChatGroupRemoteDataSource remote;

  ChatGroupRepositoryImpl(this.remote);

  @override
  Stream<List<MessageModel>> getMessages(String groupId) {
    return remote.getMessages(groupId).map(
            (list) => list.map((message) => message.toDomain()).toList());
  }

  @override
  Future<void> sendMessage(SendMessageRequest request) =>
      remote.sendMessage(request);

  @override
  Future<void> updateMessageStatus(
      String groupId, String messageId, Map<String, String> updatedStatus) =>
      remote.updateMessageStatus(
          groupId: groupId, messageId: messageId, updatedStatus: updatedStatus);
}
