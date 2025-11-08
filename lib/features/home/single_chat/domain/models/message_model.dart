// المسار: lib/features/home/single_chat/domain/models/message_model.dart

class SingleMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String content;
  final List<String> mentions;
  final String? replyTo;
  final Map<String, String> status; // userId -> status
  final Map<String, dynamic>? reactions;
  final String messageType;
  final bool isDeleted;
  final String? deletedBy;
  final bool isEdited;
  final DateTime timestamp;

  SingleMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.mentions = const [],
    this.replyTo,
    required this.status,
    this.reactions,
    this.messageType = 'text',
    this.isDeleted = false,
    this.deletedBy,
    this.isEdited = false,
    required this.timestamp,
  });

  // ✅ إضافة الـ getter المفقود
  bool get isMine => status[senderId] == 'sent';

  // ✅ حالة الرسالة للمستخدم الحالي
  String get myStatus => status[senderId] ?? 'pending';

  // ✅ حالة الرسالة للمستقبل
  String get receiverStatus => status[receiverId] ?? 'pending';

  // ✅ التحقق من الحالات
  bool get isSent => myStatus == 'sent';
  bool get isDelivered => receiverStatus == 'delivered';
  bool get isSeen => receiverStatus == 'seen';
  bool get isPending => receiverStatus == 'pending';
  bool get isFailed => receiverStatus == 'failed';

  // ✅ نسخ الرسالة مع تحديث
  SingleMessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    String? content,
    List<String>? mentions,
    String? replyTo,
    Map<String, String>? status,
    Map<String, dynamic>? reactions,
    String? messageType,
    bool? isDeleted,
    String? deletedBy,
    bool? isEdited,
    DateTime? timestamp,
  }) {
    return SingleMessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      mentions: mentions ?? this.mentions,
      replyTo: replyTo ?? this.replyTo,
      status: status ?? this.status,
      reactions: reactions ?? this.reactions,
      messageType: messageType ?? this.messageType,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedBy: deletedBy ?? this.deletedBy,
      isEdited: isEdited ?? this.isEdited,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}