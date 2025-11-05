
// المسار: lib/features/groups/data/data_source/groups_remote_data_source.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/service/cloudinart_service.dart';
import '../response/group_response.dart';

abstract class GroupsRemoteDataSource {
  Future<String> createGroup({
    required String name,
    String? description,
    required String createdBy,
    required List<String> participants,
    File? imageFile,
    bool onlyAdminsCanSend = false,
    bool allowMembersToAddOthers = false,
  });

  Future<List<GroupResponse>> getUserGroups(String userId);
  Future<void> updateGroupImage(String groupId, File imageFile);
  Future<void> addMember(String groupId, String userId);
  Future<void> removeMember(String groupId, String userId);
  Future<void> makeAdmin(String groupId, String userId);
  Future<void> removeAdmin(String groupId, String userId);
}

class GroupsRemoteDataSourceImpl implements GroupsRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<String> createGroup({
    required String name,
    String? description,
    required String createdBy,
    required List<String> participants,
    File? imageFile,
    bool onlyAdminsCanSend = false,
    bool allowMembersToAddOthers = false,
  }) async {
    try {
      // إنشاء document reference
      final groupRef = _firestore.collection('groups').doc();
      final groupId = groupRef.id;

      String? imageUrl;

      // رفع الصورة إلى Cloudinary إذا كانت موجودة
      if (imageFile != null) {
        imageUrl = await CloudinaryService.upload(
          file: imageFile,
          type: 'image',
          folder: 'chat_media/groups/$groupId',
        );
      }

      // إضافة المُنشئ للمشاركين إذا لم يكن موجوداً
      final allParticipants = List<String>.from(participants);
      if (!allParticipants.contains(createdBy)) {
        allParticipants.insert(0, createdBy);
      }

      // إنشاء المجموعة
      await groupRef.set({
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'createdBy': createdBy,
        'admins': [createdBy],
        'participants': allParticipants,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'settings': {
          'onlyAdminsCanSend': onlyAdminsCanSend,
          'onlyAdminsCanEdit': true,
          'allowMembersToAddOthers': allowMembersToAddOthers,
          'showMembersList': true,
        },
      });

      return groupId;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  @override
  Future<List<GroupResponse>> getUserGroups(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('participants', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => GroupResponse.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user groups: $e');
    }
  }

  @override
  Future<void> updateGroupImage(String groupId, File imageFile) async {
    try {
      // رفع الصورة الجديدة إلى Cloudinary
      final imageUrl = await CloudinaryService.upload(
        file: imageFile,
        type: 'image',
        folder: 'chat_media/groups/$groupId',
      );

      // تحديث رابط الصورة في Firestore
      await _firestore.collection('groups').doc(groupId).update({
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update group image: $e');
    }
  }

  @override
  Future<void> addMember(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'participants': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  @override
  Future<void> removeMember(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'participants': FieldValue.arrayRemove([userId]),
        'admins': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  @override
  Future<void> makeAdmin(String groupId, String userId) async {
    try {
      await _firestore.collection('groups').doc(groupId).update({
        'admins': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to make admin: $e');
    }
  }

  @override
  Future<void> removeAdmin(String groupId, String userId) async {
    try {
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      final admins = List<String>.from(groupDoc.data()?['admins'] ?? []);

      if (admins.length <= 1) {
        throw Exception('Cannot remove the last admin');
      }

      await _firestore.collection('groups').doc(groupId).update({
        'admins': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove admin: $e');
    }
  }
}