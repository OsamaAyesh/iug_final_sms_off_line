// المسار: lib/features/home/group_chat/domain/models/message_model.dart

class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final List<String> mentions;
  final String? replyTo;
  final Map<String, String> status; // userId -> status (seen/delivered/pending/failed)
  final DateTime timestamp;
  final bool isGroup;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    this.mentions = const [],
    this.replyTo,
    required this.status,
    required this.timestamp,
    this.isGroup = true,
  });

  // حساب عدد الأشخاص لكل حالة
  int get seenCount =>
      status.values.where((value) => value == 'seen').length;

  int get deliveredCount =>
      status.values.where((value) => value == 'delivered').length;

  int get pendingCount =>
      status.values.where((value) => value == 'pending').length;

  int get failedCount =>
      status.values.where((value) => value == 'failed').length;

  // التحقق من الحالات
  bool get isDelivered =>
      status.values.any((value) => value == 'delivered' || value == 'seen');

  bool get isSeen =>
      status.values.any((value) => value == 'seen');

  bool get isFailed =>
      status.values.any((value) => value == 'failed');

  // نسخ الرسالة مع تحديث
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? content,
    List<String>? mentions,
    String? replyTo,
    Map<String, String>? status,
    DateTime? timestamp,
    bool? isGroup,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      mentions: mentions ?? this.mentions,
      replyTo: replyTo ?? this.replyTo,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      isGroup: isGroup ?? this.isGroup,
    );
  }
}