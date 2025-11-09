import 'dart:io';
import '../../domain/models/profile_model.dart';

abstract class ProfileRepository {
  Future<ProfileModel> getProfile(String userId);
  Future<void> updateProfile(String userId, ProfileModel profile);
  Future<String> uploadProfileImage(String userId, File imageFile);
  Future<void> updateProfileImage(String userId, String imageUrl);
}