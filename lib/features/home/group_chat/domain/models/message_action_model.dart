// المسار: lib/features/home/group_chat/domain/models/message_action_model.dart

enum MessageAction {
  reply,      // الرد على الرسالة
  edit,       // تعديل الرسالة
  delete,     // حذف الرسالة
  copy,       // نسخ النص
  forward,    // إعادة توجيه
  react,      // التفاعل (👍❤️😂😮😢)
  pin,        // تثبيت الرسالة
  status,     // عرض حالة الرسالة
}

class MessageReaction {
  final String emoji;
  final List<String> userIds; // المستخدمين الذين تفاعلوا

  MessageReaction({
    required this.emoji,
    required this.userIds,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      emoji: json['emoji'] ?? '',
      userIds: List<String>.from(json['userIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'emoji': emoji,
    'userIds': userIds,
  };

  int get count => userIds.length;
}