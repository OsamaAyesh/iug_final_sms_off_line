class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final List<String> mentions;
  final String? replyTo;
  final Map<String, String> status;
  final DateTime timestamp;
  final bool isGroup;
  final Map<String, List<String>> reactions;
  final bool isEdited;
  final DateTime? editedAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    this.mentions = const [],
    this.replyTo,
    required this.status,
    required this.timestamp,
    this.isGroup = true,
    this.reactions = const {},
    this.isEdited = false,
    this.editedAt,
  });

  // دوال للتفاعلات
  List<String> getUserReactions(String userId) => reactions[userId] ?? [];
  bool hasUserReacted(String userId, String emoji) => getUserReactions(userId).contains(emoji);
  int getReactionCount(String emoji) {
    int count = 0;
    for (var userReactions in reactions.values) {
      if (userReactions.contains(emoji)) count++;
    }
    return count;
  }

  // دوال الحالات المحسنة
  int get seenCount => status.values.where((value) => value == 'seen').length;
  int get deliveredCount => status.values.where((value) => value == 'delivered').length;
  int get pendingCount => status.values.where((value) => value == 'pending').length;
  int get failedCount => status.values.where((value) => value == 'failed').length;
  int get sentCount => status.values.where((value) => value == 'sent').length;

  bool get isDelivered => deliveredCount > 0 || seenCount > 0;
  bool get isSeen => seenCount > 0;
  bool get isFailed => failedCount > 0;
  bool get isPending => pendingCount > 0;

  // نسخ مع تحديث
  MessageModel copyWith({
    String? id,
    String? senderId,
    String? content,
    List<String>? mentions,
    String? replyTo,
    Map<String, String>? status,
    DateTime? timestamp,
    bool? isGroup,
    Map<String, List<String>>? reactions,
    bool? isEdited,
    DateTime? editedAt,
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
      reactions: reactions ?? this.reactions,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}