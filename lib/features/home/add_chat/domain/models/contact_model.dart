// المسار: lib/features/contacts/domain/models/contact_model.dart

class ContactModel {
  final String id;
  final String name;
  final String phone;
  final String? imageUrl;
  final String? bio;
  final DateTime? lastSeen;
  final bool isOnline;
  final DateTime createdAt;

  ContactModel({
    required this.id,
    required this.name,
    required this.phone,
    this.imageUrl,
    this.bio,
    this.lastSeen,
    this.isOnline = false,
    required this.createdAt,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      imageUrl: json['imageUrl'],
      bio: json['bio'],
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : null,
      isOnline: json['isOnline'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'imageUrl': imageUrl,
    'bio': bio,
    'lastSeen': lastSeen?.toIso8601String(),
    'isOnline': isOnline,
    'createdAt': createdAt.toIso8601String(),
  };
}