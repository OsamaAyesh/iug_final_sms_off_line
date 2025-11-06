// المسار: lib/features/home/group_chat/data/response/message_response.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MessageResponse {
  final String? id;
  final String? senderId;
  final String? content;
  final List<String>? mentions;
  final String? replyTo;
  final Map<String, dynamic>? status;
  final Map<String, dynamic>? reactions;
  final bool? isGroup;
  final bool? isDeleted;
  final String? deletedBy;
  final DateTime? timestamp;

  MessageResponse({
    this.id,
    this.senderId,
    this.content,
    this.mentions,
    this.replyTo,
    this.status,
    this.reactions,
    this.isGroup,
    this.isDeleted,
    this.deletedBy,
    this.timestamp,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json, String id) {
    return MessageResponse(
      id: id,
      senderId: json['senderId'] as String?,
      content: json['content'] as String?,
      mentions: (json['mentions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      replyTo: json['replyTo'] as String?,
      status: Map<String, dynamic>.from(json['status'] ?? {}),
      reactions: json['reactions'] != null
          ? Map<String, dynamic>.from(json['reactions'])
          : {},
      isGroup: json['isGroup'] as bool? ?? true,
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedBy: json['deletedBy'] as String?,
      timestamp: (json['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'content': content,
    'mentions': mentions,
    'replyTo': replyTo,
    'status': status,
    'reactions': reactions,
    'isGroup': isGroup,
    'isDeleted': isDeleted,
    'deletedBy': deletedBy,
    'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
  };
}