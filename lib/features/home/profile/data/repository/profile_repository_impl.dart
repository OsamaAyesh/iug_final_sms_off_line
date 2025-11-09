import 'dart:io';
import 'package:app_mobile/features/home/profile/data/repository/profile_repository.dart';

import '../../domain/models/profile_model.dart';
import '../data_source/profile_remote_data_source.dart';
import '../mapper/profile_mapper.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ProfileModel> getProfile(String userId) async {
    try {
      final response = await remoteDataSource.getProfile(userId);
      return ProfileMapper.toModel(response);
    } catch (e) {
      throw Exception('Repository: Failed to get profile - $e');
    }
  }

  @override
  Future<void> updateProfile(String userId, ProfileModel profile) async {
    try {
      final updates = ProfileMapper.toUpdateMap(profile);
      await remoteDataSource.updateProfile(userId, updates);
    } catch (e) {
      throw Exception('Repository: Failed to update profile - $e');
    }
  }

  @override
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      return await remoteDataSource.uploadProfileImage(userId, imageFile);
    } catch (e) {
      throw Exception('Repository: Failed to upload profile image - $e');
    }
  }

  @override
  Future<void> updateProfileImage(String userId, String imageUrl) async {
    try {
      await remoteDataSource.updateProfileImage(userId, imageUrl);
    } catch (e) {
      throw Exception('Repository: Failed to update profile image - $e');
    }
  }
}