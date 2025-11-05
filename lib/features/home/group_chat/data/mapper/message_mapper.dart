import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';

import '../response/message_response.dart';

extension MessageMapper on MessageResponse {
  MessageModel toDomain() {
    return MessageModel(
      id: id ?? '',
      senderId: senderId ?? '',
      content: content ?? '',
      status: Map<String, String>.from(status ?? {}),
      timestamp: timestamp ?? DateTime.now(),
      isGroup: isGroup ?? false,
    );
  }
}
