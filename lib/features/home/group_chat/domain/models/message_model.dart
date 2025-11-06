// المسار: lib/features/home/group_chat/domain/models/message_model.dart

class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final List<String> mentions;
  final String? replyTo;
  final Map<String, String> status; // userId -> status (seen/delivered/pending/failed)
  final Map<String, dynamic>? reactions; // userId -> emoji
  final DateTime timestamp;
  final bool isGroup;
  final bool isDeleted;
  final String? deletedBy;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    this.mentions = const [],
    this.replyTo,
    required this.status,
    this.reactions,
    required this.timestamp,
    this.isGroup = true,
    this.isDeleted = false,
    this.deletedBy,
  });

  // ✅ حساب عدد الأشخاص لكل حالة
  int get seenCount =>
      status.values.where((value) => value == 'seen').length;

  int get deliveredCount =>
      status.values.where((value) => value == 'delivered').length;

  int get pendingCount =>
      status.values.where((value) => value == 'pending').length;

  int get failedCount =>
      status.values.where((value) => value == 'failed').length;

  // ✅ التحقق من الحالات - بطريقة واتساب
  bool get isFullyDelivered =>
      status.values.every((value) => value == 'delivered' || value == 'seen');

  bool get isFullySeen =>
      status.values.every((value) => value == 'seen');

  bool get isDelivered =>
      status.values.any((value) => value == 'delivered' || value == 'seen');

  bool get isSeen =>
      status.values.any((value) => value == 'seen');

  bool get isFailed =>
      status.values.any((value) => value == 'failed');

  bool get isPending =>
      status.values.any((value) => value == 'pending');

  // ✅ حالة الرسالة الإجمالية (للعرض)
  String get overallStatus {
    if (isFullySeen) return 'seen';
    if (isSeen) return 'seen'; // بعض الناس قرأوا
    if (isFullyDelivered) return 'delivered';
    if (isDelivered) return 'delivered'; // بعض الناس استلموا
    if (isFailed) return 'failed';
    return 'pending';
  }

  // ✅ نسخ الرسالة مع تحديث
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? content,
    List<String>? mentions,
    String? replyTo,
    Map<String, String>? status,
    Map<String, dynamic>? reactions,
    DateTime? timestamp,
    bool? isGroup,
    bool? isDeleted,
    String? deletedBy,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      mentions: mentions ?? this.mentions,
      replyTo: replyTo ?? this.replyTo,
      status: status ?? this.status,
      reactions: reactions ?? this.reactions,
      timestamp: timestamp ?? this.timestamp,
      isGroup: isGroup ?? this.isGroup,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }
}