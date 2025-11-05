import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomResponse {
  final String? name;
  final String? lastMessage;
  final String? lastMessageSender;
  final Timestamp? timestamp;
  final Timestamp? lastMessageTime;
  final String? groupIcon;
  final List<dynamic>? participants;
  final List<dynamic>? admins;

  ChatRoomResponse({
    this.name,
    this.lastMessage,
    this.lastMessageSender,
    this.timestamp,
    this.lastMessageTime,
    this.groupIcon,
    this.participants,
    this.admins,
  });

  factory ChatRoomResponse.fromJson(Map<String, dynamic> json) {
    return ChatRoomResponse(
      name: json['name'] ?? '',
      lastMessage: json['lastMessage'] ?? json['last_message'] ?? '',
      lastMessageSender:
      json['lastMessageSender'] ?? json['last_message_sender'] ?? '',
      timestamp: json['timestamp'],
      lastMessageTime: json['lastMessageTime'],
      groupIcon: json['groupIcon'] ?? '',
      participants: json['participants'],
      admins: json['admins'],
    );
  }
}
