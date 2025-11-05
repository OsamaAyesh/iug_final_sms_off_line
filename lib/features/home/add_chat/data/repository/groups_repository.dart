
// المسار: lib/features/groups/domain/repository/groups_repository.dart

import 'dart:io';
import 'package:app_mobile/features/home/add_chat/domain/models/group_model.dart' show GroupModel;


abstract class GroupsRepository {
  Future<String> createGroup({
    required String name,
    String? description,
    required String createdBy,
    required List<String> participants,
    File? imageFile,
    bool onlyAdminsCanSend = false,
    bool allowMembersToAddOthers = false,
  });

  Future<List<GroupModel>> getUserGroups(String userId);
  Future<GroupModel?> getGroupById(String groupId);
  Future<void> updateGroupName(String groupId, String name);
  Future<void> updateGroupDescription(String groupId, String description);
  Future<void> updateGroupImage(String groupId, File imageFile);
  Future<void> deleteGroup(String groupId);
  Future<void> addMember(String groupId, String userId);
  Future<void> removeMember(String groupId, String userId);
  Future<void> makeAdmin(String groupId, String userId);
  Future<void> removeAdmin(String groupId, String userId);
}