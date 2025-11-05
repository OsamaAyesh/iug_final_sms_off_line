import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
import '../data_source/chat_group_remote_data_source.dart';
import '../mapper/message_mapper.dart';
import '../request/send_message_request.dart';
import 'chat_group_repository.dart';

class ChatGroupRepositoryImpl implements ChatGroupRepository {
  final ChatGroupRemoteDataSource remote;

  ChatGroupRepositoryImpl(this.remote);

  @override
  Stream<List<MessageModel>> getMessages(String groupId, String currentUserId) {
    return remote.getMessages(groupId, currentUserId).map(
            (list) => list.map((message) => message.toDomain()).toList());
  }

  @override
  Future<void> sendMessage(SendMessageRequest request) =>
      remote.sendMessage(request);

  @override
  Future<void> updateMessageStatus({
    required String groupId,
    required String messageId,
    required String userId,
    required String status,
  }) =>
      remote.updateMessageStatus(
        groupId: groupId,
        messageId: messageId,
        userId: userId,
        status: status,
      );

  @override
  Future<void> batchUpdateMessageStatus({
    required String groupId,
    required List<String> messageIds,
    required String userId,
    required String status,
  }) =>
      remote.batchUpdateMessageStatus(
        groupId: groupId,
        messageIds: messageIds,
        userId: userId,
        status: status,
      );

  @override
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) =>
      remote.getGroupMembers(groupId);

  @override
  Future<void> markMessagesAsSeen({
    required String groupId,
    required String userId,
  }) =>
      remote.markMessagesAsSeen(
        groupId: groupId,
        userId: userId,
      );

  @override
  Future<void> markMessageAsDelivered({
    required String groupId,
    required String messageId,
    required String userId,
  }) =>
      remote.markMessageAsDelivered(
        groupId: groupId,
        messageId: messageId,
        userId: userId,
      );

  @override
  Future<Map<String, int>> sendSmsToUsers(
      String groupId,
      List<String> numbers,
      String text,
      ) =>
      remote.sendSmsToUsers(groupId, numbers, text);

  @override
  Future<void> toggleMessageReaction({
    required String groupId,
    required String messageId,
    required String userId,
    required String emoji,
  }) =>
      remote.toggleMessageReaction(
        groupId: groupId,
        messageId: messageId,
        userId: userId,
        emoji: emoji,
      );

  @override
  Future<void> deleteMessage({
    required String groupId,
    required String messageId,
    required String userId,
    required bool isAdmin,
  }) =>
      remote.deleteMessage(
        groupId: groupId,
        messageId: messageId,
        userId: userId,
        isAdmin: isAdmin,
      );

  @override
  Stream<Map<String, dynamic>> getUserConnectionStatus(String userId) =>
      remote.getUserConnectionStatus(userId);

  @override
  Future<void> updateUserConnectionStatus(String userId, bool isOnline) =>
      remote.updateUserConnectionStatus(userId, isOnline);
}