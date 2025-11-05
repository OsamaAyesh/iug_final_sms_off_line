// المسار: lib/features/home/group_chat/domain/models/group_member_model.dart

class GroupMemberModel {
  final String userId;
  final String name;
  final String imageUrl;
  final String? phoneNumber;
  final bool isAdmin;
  final bool isOnline;
  final DateTime? lastSeen;

  GroupMemberModel({
    required this.userId,
    required this.name,
    required this.imageUrl,
    this.phoneNumber,
    this.isAdmin = false,
    this.isOnline = false,
    this.lastSeen,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      phoneNumber: json['phoneNumber'],
      isAdmin: json['isAdmin'] ?? false,
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'imageUrl': imageUrl,
    'phoneNumber': phoneNumber,
    'isAdmin': isAdmin,
    'isOnline': isOnline,
    'lastSeen': lastSeen?.toIso8601String(),
  };
}