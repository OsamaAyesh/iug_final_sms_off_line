// المسار: lib/features/contacts/data/response/contact_response.dart

class ContactResponse {
  final String id;
  final String name;
  final String phone;
  final String? phoneCanon;
  final String? imageUrl;
  final String? bio;
  final String? lastSeen;
  final bool isOnline;
  final String createdAt;

  ContactResponse({
    required this.id,
    required this.name,
    required this.phone,
    this.phoneCanon,
    this.imageUrl,
    this.bio,
    this.lastSeen,
    required this.isOnline,
    required this.createdAt,
  });

  factory ContactResponse.fromJson(String id, Map<String, dynamic> json) {
    return ContactResponse(
      id: id,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      phoneCanon: json['phoneCanon'],
      imageUrl: json['imageUrl'],
      bio: json['bio'],
      lastSeen: json['lastSeen'],
      isOnline: json['isOnline'] ?? false,
      createdAt: json['createdAt'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'phoneCanon': phoneCanon,
    'imageUrl': imageUrl,
    'bio': bio,
    'lastSeen': lastSeen,
    'isOnline': isOnline,
    'createdAt': createdAt,
  };
}