class MessageStatusModel {
  final String userId;
  final String name;
  final String imageUrl;
   String status; // delivered / seen / failed / pending

  MessageStatusModel({
    required this.userId,
    required this.name,
    required this.imageUrl,
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
}
