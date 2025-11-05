import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';

import '../request/send_message_request.dart';

abstract class ChatGroupRepository {
  Stream<List<MessageModel>> getMessages(String groupId);
  Future<void> sendMessage(SendMessageRequest request);
  Future<void> updateMessageStatus(
      String groupId,
      String messageId,
      Map<String, String> updatedStatus,
      );
}
