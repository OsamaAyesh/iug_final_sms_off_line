// المسار: lib/features/home/single_chat/data/mapper/message_mapper.dart

import 'package:app_mobile/features/home/single_chat/domain/models/message_model.dart';
import '../response/message_response.dart';

extension SingleMessageMapper on SingleMessageResponse {
  SingleMessageModel toDomain() {
    return SingleMessageModel(
      id: id ?? '',
      chatId: chatId ?? '',
      senderId: senderId ?? '',
      receiverId: receiverId ?? '',
      content: content ?? '',
      mentions: mentions ?? [],
      replyTo: replyTo,
      status: (status ?? {}).map((key, value) => MapEntry(key, value.toString())),
      reactions: reactions,
      messageType: messageType ?? 'text',
      isDeleted: isDeleted ?? false,
      deletedBy: deletedBy,
      isEdited: isEdited ?? false,
      timestamp: timestamp ?? DateTime.now(),
    );
  }
}