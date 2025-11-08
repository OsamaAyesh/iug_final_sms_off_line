// المسار: lib/features/home/single_chat/data/repository/single_chat_repository_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_mobile/features/home/single_chat/domain/models/message_model.dart';
import '../data_source/single_chat_remote_data_source.dart';
import '../mapper/message_mapper.dart';
import '../request/send_message_request.dart';
import 'single_chat_repository.dart';

class SingleChatRepositoryImpl implements SingleChatRepository {
  final SingleChatRemoteDataSource remote;

  SingleChatRepositoryImpl(this.remote);

  @override
  Future<String> getOrCreateChatId(String user1Id, String user2Id) =>
      remote.getOrCreateChatId(user1Id, user2Id);

  @override
  Stream<List<SingleMessageModel>> getMessages(String chatId) {
    return remote.getMessages(chatId).map(
            (list) => list.map((message) => message.toDomain()).toList());
  }

  @override
  Future<void> sendMessage(SendSingleMessageRequest request) =>
      remote.sendMessage(request);

  @override
  Future<void> updateMessageStatus({
    required String chatId,
    required String messageId,
    required String userId,
    required String status,
  }) =>
      remote.updateMessageStatus(
        chatId: chatId,
        messageId: messageId,
        userId: userId,
        status: status,
      );

  @override
  Future<void> markMessagesAsDelivered({
    required String chatId,
    required String userId,
  }) =>
      remote.markMessagesAsDelivered(
        chatId: chatId,
        userId: userId,
      );

  @override
  Future<void> markMessagesAsSeen({
    required String chatId,
    required String userId,
    required String otherUserId,
  }) =>
      remote.markMessagesAsSeen(
        chatId: chatId,
        userId: userId,
        otherUserId: otherUserId,
      );

  @override
  Future<void> addOrUpdateReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
  }) =>
      remote.addOrUpdateReaction(
        chatId: chatId,
        messageId: messageId,
        userId: userId,
        emoji: emoji,
      );

  @override
  Future<void> removeReaction({
    required String chatId,
    required String messageId,
    required String userId,
  }) =>
      remote.removeReaction(
        chatId: chatId,
        messageId: messageId,
        userId: userId,
      );

  @override
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required String deletedBy,
  }) =>
      remote.deleteMessage(
        chatId: chatId,
        messageId: messageId,
        deletedBy: deletedBy,
      );

  @override
  Future<Map<String, dynamic>> getUserInfo(String userId) =>
      remote.getUserInfo(userId);

  @override
  Future<Map<String, dynamic>> sendSmsToUser(
      String chatId, String number, String text, String messageId) =>
      remote.sendSmsToUser(chatId, number, text, messageId);

  @override
  Stream<QuerySnapshot> getUserChats(String userId) =>
      remote.getUserChats(userId);
}