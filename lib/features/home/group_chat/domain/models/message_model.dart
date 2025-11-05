class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final List<String> mentions;
  final String? replyTo;
  final Map<String, String> status;
  final DateTime timestamp;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.mentions,
    this.replyTo,
    required this.status,
    required this.timestamp,
  });

  bool get isDelivered =>
      status.values.any((value) => value == 'delivered');
  bool get isSeen => status.values.every((value) => value == 'seen');
  bool get isFailed =>
      status.values.any((value) => value == 'failed');
}
