// المسار: lib/features/groups/data/request/create_group_request.dart

class CreateGroupRequest {
  final String name;
  final String? description;
  final String? imageUrl;
  final String createdBy;
  final List<String> participants;
  final bool onlyAdminsCanSend;
  final bool allowMembersToAddOthers;

  CreateGroupRequest({
    required this.name,
    this.description,
    this.imageUrl,
    required this.createdBy,
    required this.participants,
    this.onlyAdminsCanSend = false,
    this.allowMembersToAddOthers = false,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'createdBy': createdBy,
    'admins': [createdBy],
    'participants': [...participants, createdBy],
    'createdAt': DateTime.now().toIso8601String(),
    'settings': {
      'onlyAdminsCanSend': onlyAdminsCanSend,
      'onlyAdminsCanEdit': true,
      'allowMembersToAddOthers': allowMembersToAddOthers,
      'showMembersList': true,
    },
    'unread_by': {
      for (var userId in participants) userId: 0,
    },
  };
}