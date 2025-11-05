// المسار: lib/features/home/group_chat/domain/models/message_status_model.dart

class MessageStatusModel {
  final String userId;
  final String name;
  final String imageUrl;
  final String? phoneNumber;
  String status; // delivered / seen / failed / pending

  MessageStatusModel({
    required this.userId,
    required this.name,
    required this.imageUrl,
    this.phoneNumber,
    required this.status,
  });

  String get statusText {
    switch (status) {
      case "seen":
        return "قرأ الرسالة";
      case "delivered":
        return "تم التوصيل";
      case "failed":
        return "فشل الإرسال";
      case "pending":
        return "قيد الإرسال";
      default:
        return "غير معروف";
    }
  }

  factory MessageStatusModel.fromJson(Map<String, dynamic> json) {
    return MessageStatusModel(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      phoneNumber: json['phoneNumber'],
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'imageUrl': imageUrl,
    'phoneNumber': phoneNumber,
    'status': status,
  };
}