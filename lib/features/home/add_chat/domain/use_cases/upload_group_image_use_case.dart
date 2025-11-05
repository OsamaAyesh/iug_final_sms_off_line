// المسار: lib/features/groups/domain/use_cases/upload_group_image_usecase.dart

import 'dart:io';
import '../../data/repository/groups_repository.dart';

class UploadGroupImageUseCase {
  final GroupsRepository repository;

  UploadGroupImageUseCase(this.repository);

  Future<void> call(String groupId, File imageFile) async {
    try {
      await repository.updateGroupImage(groupId, imageFile);
    } catch (e) {
      throw Exception('UseCase: Failed to upload group image - $e');
    }
  }
}