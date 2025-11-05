
// المسار: lib/features/groups/domain/use_cases/create_group_usecase.dart

import 'dart:io';

import '../../data/repository/groups_repository.dart';

class CreateGroupUseCase {
  final GroupsRepository repository;

  CreateGroupUseCase(this.repository);

  Future<String> call(CreateGroupParams params) async {
    try {
      return await repository.createGroup(
        name: params.name,
        description: params.description,
        createdBy: params.createdBy,
        participants: params.participants,
        imageFile: params.imageFile,
        onlyAdminsCanSend: params.onlyAdminsCanSend,
        allowMembersToAddOthers: params.allowMembersToAddOthers,
      );
    } catch (e) {
      throw Exception('UseCase: Failed to create group - $e');
    }
  }
}

class CreateGroupParams {
  final String name;
  final String? description;
  final String createdBy;
  final List<String> participants;
  final File? imageFile;
  final bool onlyAdminsCanSend;
  final bool allowMembersToAddOthers;

  CreateGroupParams({
    required this.name,
    this.description,
    required this.createdBy,
    required this.participants,
    this.imageFile,
    this.onlyAdminsCanSend = false,
    this.allowMembersToAddOthers = false,
  });
}