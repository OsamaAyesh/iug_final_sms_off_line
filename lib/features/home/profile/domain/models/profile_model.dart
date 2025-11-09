class ProfileModel {
  final String id;
  final String name;
  final String phone;
  final String? phoneCanon;
  final String? imageUrl;
  final String? bio;
  final DateTime? lastSeen;
  final bool isOnline;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProfileModel({
    required this.id,
    required this.name,
    required this.phone,
    this.phoneCanon,
    this.imageUrl,
    this.bio,
    this.lastSeen,
    required this.isOnline,
    required this.isVerified,
    required this.createdAt,
    this.updatedAt,
  });

  ProfileModel copyWith({
    String? name,
    String? bio,
    String? imageUrl,
    bool? isOnline,
    DateTime? lastSeen,
  }) {
    return ProfileModel(
      id: id,
      name: name ?? this.name,
      phone: phone,
      phoneCanon: phoneCanon,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'phoneCanon': phoneCanon,
    'imageUrl': imageUrl,
    'bio': bio,
    'lastSeen': lastSeen?.toIso8601String(),
    'isOnline': isOnline,
    'isVerified': isVerified,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}