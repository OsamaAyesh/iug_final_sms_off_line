import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileResponse {
  final String id;
  final String name;
  final String phone;
  final String? phoneCanon;
  final String? imageUrl;
  final String? bio;
  final dynamic lastSeen;
  final bool isOnline;
  final bool isVerified;
  final dynamic createdAt;
  final dynamic updatedAt;

  ProfileResponse({
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

  factory ProfileResponse.fromJson(String id, Map<String, dynamic> json) {
    return ProfileResponse(
      id: id,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      phoneCanon: json['phoneCanon'],
      imageUrl: json['imageUrl'],
      bio: json['bio'],
      lastSeen: json['lastSeen'],
      isOnline: json['isOnline'] ?? false,
      isVerified: json['isVerified'] ?? false,
      // ✅ إصلاح: استخدام قيمة افتراضية إذا كانت null
      createdAt: json['createdAt'] ?? FieldValue.serverTimestamp(),
      updatedAt: json['updatedAt'],
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
    'isVerified': isVerified,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}