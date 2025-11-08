// المسار: lib/features/home/single_chat/data/request/send_message_request.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SendSingleMessageRequest {
  final String chatId;
  final String senderId;
  final String receiverId;
  final String content;
  final List<String> mentions;
  final String? replyTo;
  final DateTime timestamp;
  final String messageType; // text, image, voice, file

  SendSingleMessageRequest({
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.mentions = const [],
    this.replyTo,
    required this.timestamp,
    this.messageType = 'text',
  });

  Map<String, dynamic> toJson() => {
    'chatId': chatId,
    'senderId': senderId,
    'receiverId': receiverId,
    'content': content,
    'mentions': mentions,
    'replyTo': replyTo,
    'timestamp': Timestamp.fromDate(timestamp),
    'messageType': messageType,
    'status': {
      senderId: 'sent',
      receiverId: 'pending'
    },
    'reactions': {},
    'isDeleted': false,
    'deletedBy': null,
    'isEdited': false,
  };
}