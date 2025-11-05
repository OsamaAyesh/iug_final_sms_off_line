// المسار: lib/features/home/group_chat/data/mapper/message_mapper.dart

import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';
import '../response/message_response.dart';

extension MessageMapper on MessageResponse {
  MessageModel toDomain() {
    return MessageModel(
      id: id ?? '',
      senderId: senderId ?? '',
      content: content ?? '',
      mentions: mentions ?? [],
      replyTo: replyTo,
      status: (status ?? {}).map((key, value) => MapEntry(key, value.toString())),
      timestamp: timestamp ?? DateTime.now(),
      isGroup: isGroup ?? true,
    );
  }
}