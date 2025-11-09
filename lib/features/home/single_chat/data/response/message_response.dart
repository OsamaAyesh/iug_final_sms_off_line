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
    // ✅ تأكيد أن status دائماً Map
    Map<String, dynamic> parsedStatus = {};
    if (json['status'] is Map) {
      parsedStatus = Map<String, dynamic>.from(json['status']);
    } else if (json['status'] is String) {
      parsedStatus = {'default': json['status']}; // حفظ القيمة القديمة بدون كسر الكود
    }

    // ✅ تأكيد أن reactions دائماً Map
    Map<String, dynamic> parsedReactions = {};
    if (json['reactions'] is Map) {
      parsedReactions = Map<String, dynamic>.from(json['reactions']);
    }

    // ✅ التعامل مع timestamp بأمان
    DateTime? parsedTimestamp;
    if (json['timestamp'] is Timestamp) {
      parsedTimestamp = (json['timestamp'] as Timestamp).toDate();
    } else if (json['timestamp'] is String) {
      parsedTimestamp = DateTime.tryParse(json['timestamp']);
    }

    return SingleMessageResponse(
      id: id,
      chatId: json['chatId'] as String?,
      senderId: json['senderId'] as String?,
      receiverId: json['receiverId'] as String?,
      content: json['content'] as String?,
      mentions: (json['mentions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      replyTo: json['replyTo'] as String?,
      status: parsedStatus,
      reactions: parsedReactions,
      messageType: json['messageType'] as String? ?? 'text',
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedBy: json['deletedBy'] as String?,
      isEdited: json['isEdited'] as bool? ?? false,
      timestamp: parsedTimestamp,
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