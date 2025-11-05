class ChatRoomModel {
  final String id;
  final String name;
  final String lastMessage;
  final String lastMessageSender;
  final String time;
  final bool isGroup;
  final String imageUrl;
  final int membersCount;

  ChatRoomModel({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.lastMessageSender,
    required this.time,
    required this.isGroup,
    required this.imageUrl,
    required this.membersCount,
  });
}
