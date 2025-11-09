import 'package:cloud_firestore/cloud_firestore.dart';
import '../response/profile_response.dart';
import '../../domain/models/profile_model.dart';

class ProfileMapper {
  static ProfileModel toModel(ProfileResponse response) {
    return ProfileModel(
      id: response.id,
      name: response.name,
      phone: response.phone,
      phoneCanon: response.phoneCanon,
      imageUrl: response.imageUrl,
      bio: response.bio,
      lastSeen: _parseToDateTime(response.lastSeen),
      isOnline: response.isOnline,
      isVerified: response.isVerified,
      createdAt: _parseToDateTime(response.createdAt) ?? DateTime.now(),
      updatedAt: _parseToDateTime(response.updatedAt),
    );
  }

  static ProfileResponse toResponse(ProfileModel model) {
    return ProfileResponse(
      id: model.id,
      name: model.name,
      phone: model.phone,
      phoneCanon: model.phoneCanon,
      imageUrl: model.imageUrl,
      bio: model.bio,
      lastSeen: model.lastSeen?.toIso8601String(),
      isOnline: model.isOnline,
      isVerified: model.isVerified,
      createdAt: model.createdAt.toIso8601String(),
      updatedAt: model.updatedAt?.toIso8601String(),
    );
  }

  static Map<String, dynamic> toUpdateMap(ProfileModel model) {
    return {
      'name': model.name,
      'bio': model.bio,
      'imageUrl': model.imageUrl,
      'isOnline': model.isOnline,
      'lastSeen': model.lastSeen != null ? Timestamp.fromDate(model.lastSeen!) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ✅ دالة شاملة لتحويل أي نوع إلى DateTime
  static DateTime? _parseToDateTime(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing DateTime from string: $value, error: $e');
        return null;
      }
    } else if (value is DateTime) {
      return value;
    } else {
      print('Unknown type for DateTime parsing: ${value.runtimeType}');
      return null;
    }
  }

  // ✅ دالة لتحويل البيانات من Firebase إلى Response
  static ProfileResponse fromFirebaseDoc(String id, Map<String, dynamic> data) {
    return ProfileResponse(
      id: id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      phoneCanon: data['phoneCanon'],
      imageUrl: data['imageUrl'],
      bio: data['bio'],
      lastSeen: data['lastSeen'],
      isOnline: data['isOnline'] ?? false,
      isVerified: data['isVerified'] ?? false,
      createdAt: data['createdAt'] ?? FieldValue.serverTimestamp(),
      updatedAt: data['updatedAt'],
    );
  }
}