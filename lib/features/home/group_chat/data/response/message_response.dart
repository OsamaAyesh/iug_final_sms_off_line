import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message_response.g.dart';

@JsonSerializable()
class MessageResponse {
  final String? id;
  final String? senderId;
  final String? content;
  final Map<String, dynamic>? status;
  final bool? isGroup;
  final DateTime? timestamp;

  MessageResponse({
    this.id,
    this.senderId,
    this.content,
    this.status,
    this.isGroup,
    this.timestamp,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json, String id) {
    return MessageResponse(
      id: id,
      senderId: json['senderId'] as String?,
      content: json['content'] as String?,
      status: Map<String, dynamic>.from(json['status'] ?? {}),
      isGroup: json['isGroup'] as bool? ?? false,
      timestamp: (json['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'content': content,
    'status': status,
    'isGroup': isGroup,
    'timestamp': timestamp,
  };
}
