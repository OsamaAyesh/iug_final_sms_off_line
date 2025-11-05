import 'package:cloud_firestore/cloud_firestore.dart';

class SendMessageRequest {
  final String groupId;
  final String senderId;
  final String content;
  final List<String> mentions;
  final String? replyTo;
  final DateTime timestamp;

  SendMessageRequest({
    required this.groupId,
    required this.senderId,
    required this.content,
    this.mentions = const [],
    this.replyTo,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'groupId': groupId,
    'senderId': senderId,
    'content': content,
    'mentions': mentions,
    'replyTo': replyTo,
    'timestamp': Timestamp.fromDate(timestamp),
    'status': {}, // سيتم تعبئتها من قبل الخادم
    'isGroup': true,
    'reactions': {},
    'isEdited': false,
  };
}