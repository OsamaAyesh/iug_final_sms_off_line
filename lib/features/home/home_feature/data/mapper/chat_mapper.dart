import 'package:intl/intl.dart';
import '../../domain/models/chat_room_model.dart';
import '../response/chat_room_response.dart';

extension ChatMapper on ChatRoomResponse {
  ChatRoomModel toDomain(String id, bool isGroup) {
    final formattedTime = (lastMessageTime ?? timestamp) != null
        ? DateFormat('h:mm a').format(
      (lastMessageTime ?? timestamp)!.toDate(),
    )
        : '';

    final count = isGroup
        ? (admins?.length ?? 0)
        : (participants?.length ?? 0);

    return ChatRoomModel(
      id: id,
      name: name ?? 'بدون اسم',
      lastMessage: lastMessage ?? '',
      lastMessageSender: lastMessageSender ?? '',
      time: formattedTime,
      isGroup: isGroup,
      imageUrl: groupIcon ?? '',
      membersCount: count,
    );
  }
}
