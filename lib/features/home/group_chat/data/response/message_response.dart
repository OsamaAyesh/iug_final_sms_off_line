import 'package:cloud_firestore/cloud_firestore.dart';

class MessageResponse {
  final String? id;
  final String? senderId;
  final String? content;
  final List<String>? mentions;
  final String? replyTo;
  final Map<String, dynamic>? status;
  final bool? isGroup;
  final DateTime? timestamp;
  final Map<String, dynamic>? reactions;
  final bool? isEdited;
  final DateTime? editedAt;

  MessageResponse({
    this.id,
    this.senderId,
    this.content,
    this.mentions,
    this.replyTo,
    this.status,
    this.isGroup,
    this.timestamp,
    this.reactions,
    this.isEdited,
    this.editedAt,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json, String id) {
    try {
      // معالجة آمنة للحالة
      Map<String, dynamic> statusMap = {};
      final statusData = json['status'];
      if (statusData is Map<String, dynamic>) {
        statusMap = statusData;
      } else if (statusData is Map<dynamic, dynamic>) {
        statusMap = statusData.cast<String, dynamic>();
      }

      // معالجة آمنة للتفاعلات
      Map<String, dynamic> reactionsMap = {};
      final reactionsData = json['reactions'];
      if (reactionsData is Map<String, dynamic>) {
        reactionsMap = reactionsData;
      } else if (reactionsData is Map<dynamic, dynamic>) {
        reactionsMap = reactionsData.cast<String, dynamic>();
      }

      // معالجة آمنة للمنشن
      List<String> mentionsList = [];
      final mentionsData = json['mentions'];
      if (mentionsData is List<dynamic>) {
        mentionsList = mentionsData.map((e) => e.toString()).toList();
      }

      return MessageResponse(
        id: id,
        senderId: _safeString(json['senderId']),
        content: _safeString(json['content']),
        mentions: mentionsList,
        replyTo: _safeString(json['replyTo']),
        status: statusMap,
        isGroup: json['isGroup'] as bool? ?? true,
        timestamp: _safeTimestamp(json['timestamp']),
        reactions: reactionsMap,
        isEdited: json['isEdited'] as bool? ?? false,
        editedAt: _safeTimestamp(json['editedAt']),
      );
    } catch (e) {
      print('❌ Error creating MessageResponse: $e');
      print('📄 JSON data: $json');

      // إرجاع رسالة افتراضية في حالة الخطأ
      return MessageResponse(
        id: id,
        senderId: 'unknown',
        content: 'رسالة غير قابلة للقراءة',
        mentions: [],
        status: {},
        timestamp: DateTime.now(),
        isGroup: true,
        reactions: {},
        isEdited: false,
      );
    }
  }

// دوال مساعدة للتحويل الآمن
  static String _safeString(dynamic value) {
    if (value is String) return value;
    return value?.toString() ?? '';
  }

  static DateTime? _safeTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'content': content,
    'mentions': mentions,
    'replyTo': replyTo,
    'status': status,
    'isGroup': isGroup,
    'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
    'reactions': reactions,
    'isEdited': isEdited,
    'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
  };
}