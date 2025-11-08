// المسار: lib/features/home/group_chat/data/response/message_response.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MessageResponse {
  final String? id;
  final String? senderId;
  final String? content;
  final List<String>? mentions;
  final String? replyTo;
  final Map<String, dynamic>? status; // userId -> status
  final Map<String, dynamic>? reactions; // userId -> emoji
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
    try {
      // ✅ معالجة حقل status بشكل آمن
      Map<String, dynamic>? statusMap;
      if (json['status'] != null) {
        if (json['status'] is Map) {
          statusMap = Map<String, dynamic>.from(json['status']);
        } else if (json['status'] is String) {
          // إذا كان String، نحوله إلى Map
          statusMap = {json['senderId']: json['status']};
        }
      }

      // ✅ معالجة حقل reactions بشكل آمن
      Map<String, dynamic>? reactionsMap;
      if (json['reactions'] != null && json['reactions'] is Map) {
        reactionsMap = Map<String, dynamic>.from(json['reactions']);
      } else {
        reactionsMap = {};
      }

      // ✅ معالجة حقل mentions بشكل آمن
      List<String> mentionsList = [];
      if (json['mentions'] != null) {
        if (json['mentions'] is List) {
          mentionsList = List<String>.from(
            json['mentions'].map((e) => e.toString()),
          );
        } else if (json['mentions'] is String) {
          mentionsList = [json['mentions']];
        }
      }

      return MessageResponse(
        id: id,
        senderId: _safeString(json['senderId']),
        content: _safeString(json['content']),
        mentions: mentionsList,
        replyTo: _safeString(json['replyTo']),
        status: statusMap ?? {},
        reactions: reactionsMap ?? {},
        isGroup: json['isGroup'] as bool? ?? true,
        isDeleted: json['isDeleted'] as bool? ?? false,
        deletedBy: _safeString(json['deletedBy']),
        timestamp: _safeTimestamp(json['timestamp']),
      );
    } catch (e) {
      print('❌ Error parsing message $id: $e');
      print('❌ Message data: $json');

      // ✅ إرجاع رسالة افتراضية في حالة الخطأ
      return MessageResponse(
        id: id,
        senderId: 'unknown',
        content: 'تعذر تحميل الرسالة',
        mentions: [],
        status: {},
        reactions: {},
        isGroup: true,
        isDeleted: false,
        timestamp: DateTime.now(),
      );
    }
  }

  // ✅ دوال مساعدة للتحقق الآمن من الأنواع
  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static DateTime? _safeTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    try {
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
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
// // المسار: lib/features/home/group_chat/data/response/message_response.dart
//
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class MessageResponse {
//   final String? id;
//   final String? senderId;
//   final String? content;
//   final List<String>? mentions;
//   final String? replyTo;
//   final Map<String, dynamic>? status;
//   final Map<String, dynamic>? reactions;
//   final bool? isGroup;
//   final bool? isDeleted;
//   final String? deletedBy;
//   final DateTime? timestamp;
//
//   MessageResponse({
//     this.id,
//     this.senderId,
//     this.content,
//     this.mentions,
//     this.replyTo,
//     this.status,
//     this.reactions,
//     this.isGroup,
//     this.isDeleted,
//     this.deletedBy,
//     this.timestamp,
//   });
//
//   factory MessageResponse.fromJson(Map<String, dynamic> json, String id) {
//     return MessageResponse(
//       id: id,
//       senderId: json['senderId'] as String?,
//       content: json['content'] as String?,
//       mentions: (json['mentions'] as List<dynamic>?)
//           ?.map((e) => e.toString())
//           .toList() ??
//           [],
//       replyTo: json['replyTo'] as String?,
//       status: Map<String, dynamic>.from(json['status'] ?? {}),
//       reactions: json['reactions'] != null
//           ? Map<String, dynamic>.from(json['reactions'])
//           : {},
//       isGroup: json['isGroup'] as bool? ?? true,
//       isDeleted: json['isDeleted'] as bool? ?? false,
//       deletedBy: json['deletedBy'] as String?,
//       timestamp: (json['timestamp'] as Timestamp?)?.toDate(),
//     );
//   }
//
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'senderId': senderId,
//     'content': content,
//     'mentions': mentions,
//     'replyTo': replyTo,
//     'status': status,
//     'reactions': reactions,
//     'isGroup': isGroup,
//     'isDeleted': isDeleted,
//     'deletedBy': deletedBy,
//     'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : null,
//   };
// }