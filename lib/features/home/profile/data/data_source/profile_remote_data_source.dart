import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_mobile/core/service/cloudinart_service.dart';
import '../response/profile_response.dart';
import '../mapper/profile_mapper.dart'; // ✅ استيراد الماببر

abstract class ProfileRemoteDataSource {
  Future<ProfileResponse> getProfile(String userId);
  Future<void> updateProfile(String userId, Map<String, dynamic> updates);
  Future<String> uploadProfileImage(String userId, File imageFile);
  Future<void> updateProfileImage(String userId, String imageUrl);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore _firestore;

  ProfileRemoteDataSourceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<ProfileResponse> getProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        throw Exception('User not found');
      }

      // ✅ استخدام الماببر الجديد لمعالجة بيانات Firebase
      return ProfileMapper.fromFirebaseDoc(doc.id, doc.data()!);
    } catch (e) {
      print('❌ Error getting profile from Firebase: $e');
      throw Exception('Failed to get profile: $e');
    }
  }

  @override
  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  @override
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      final imageUrl = await CloudinaryService.upload(
        file: imageFile,
        type: 'image',
        folder: 'profile_images/$userId',
      );
      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  @override
  Future<void> updateProfileImage(String userId, String imageUrl) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update profile image: $e');
    }
  }
}