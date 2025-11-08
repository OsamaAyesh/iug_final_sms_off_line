// المسار: lib/features/home/single_chat/data/response/message_response.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SingleMessageResponse {
  final String? id;
  final String? chatId;
  final String? senderId;
  final String? receiverId;
  final String? content;
  final List<String>? mentions;
  final String? replyTo;
  final Map<String, dynamic>? status;
  final Map<String, dynamic>? reactions;
  final String? messageType;
  final bool? isDeleted;
  final String? deletedBy;
  final bool? isEdited;
  final DateTime? timestamp;

  SingleMessageResponse({
    this.id,
    this.chatId,
    this.senderId,
    this.receiverId,
    this.content,
    this.mentions,
    this.replyTo,
    this.status,
    this.reactions,
    this.messageType = 'text',
    this.isDeleted,
    this.deletedBy,
    this.isEdited,
    this.timestamp,
  });

  factory SingleMessageResponse.fromJson(Map<String, dynamic> json, String id) {
    return SingleMessageResponse(
      id: id,
      chatId: json['chatId'] as String?,
      senderId: json['senderId'] as String?,
      receiverId: json['receiverId'] as String?,
      content: json['content'] as String?,
      mentions: (json['mentions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      replyTo: json['replyTo'] as String?,
      status: Map<String, dynamic>.from(json['status'] ?? {}),
      reactions: json['reactions'] != null
          ? Map<String, dynamic>.from(json['reactions'])
          : {},
      messageType: json['messageType'] as String? ?? 'text',
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedBy: json['deletedBy'] as String?,
      isEdited: json['isEdited'] as bool? ?? false,
      timestamp: (json['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'chatId': chatId,
    'senderId': senderId,
    'receiverId': receiverId,
    'content': content,
    'mentions': mentions,
    'replyTo': replyTo,
    'status': status,
    'reactions': reactions,
    'messageType': messageType,
    'isDeleted': isDeleted,
    'deletedBy': deletedBy,
    'isEdited': isEdited,
    'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
  };
}