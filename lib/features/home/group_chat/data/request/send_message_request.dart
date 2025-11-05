class SendMessageRequest {
  final String groupId;
  final String senderId;
  final String content;
  final List<String> mentions;
  final String? replyTo;
  final DateTime timestamp;

  SendMessageRequest({
    required this.groupId,
    required this.senderId,
    required this.content,
    required this.mentions,
    this.replyTo,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'content': content,
    'mentions': mentions,
    'replyTo': replyTo,
    'timestamp': timestamp,
    'status': {},
  };
}
