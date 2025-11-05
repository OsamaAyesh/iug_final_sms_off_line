// المسار: lib/features/home/group_chat/data/repository/chat_group_repository.dart

import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
import '../request/send_message_request.dart';

abstract class ChatGroupRepository {
  /// Get messages stream for a group
  Stream<List<MessageModel>> getMessages(String groupId);

  /// Send a new message
  Future<void> sendMessage(SendMessageRequest request);

  /// Update message status for a user
  Future<void> updateMessageStatus({
    required String groupId,
    required String messageId,
    required String userId,
    required String status,
  });

  /// Batch update message status
  Future<void> batchUpdateMessageStatus({
    required String groupId,
    required List<String> messageIds,
    required String userId,
    required String status,
  });

  /// Get group members
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId);

  /// Mark messages as seen
  Future<void> markMessagesAsSeen({
    required String groupId,
    required String userId,
  });

  /// Mark message as delivered
  Future<void> markMessageAsDelivered({
    required String groupId,
    required String messageId,
    required String userId,
  });

  /// Send SMS to users
  Future<Map<String, int>> sendSmsToUsers(
      String groupId,
      List<String> numbers,
      String text,
      );
}