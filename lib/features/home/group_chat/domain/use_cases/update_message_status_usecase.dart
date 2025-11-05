// المسار: lib/features/home/group_chat/domain/use_cases/update_message_status_usecase.dart

import '../../data/repository/chat_group_repository.dart';

class UpdateMessageStatusUseCase {
  final ChatGroupRepository repository;

  UpdateMessageStatusUseCase(this.repository);

  Future<void> call({
    required String groupId,
    required String messageId,
    required String userId,
    required String status,
  }) =>
      repository.updateMessageStatus(
        groupId: groupId,
        messageId: messageId,
        userId: userId,
        status: status,
      );
}