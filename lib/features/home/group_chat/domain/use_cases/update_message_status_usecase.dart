
import '../../data/repository/chat_group_repository.dart';

class UpdateMessageStatusUseCase {
  final ChatGroupRepository repository;

  UpdateMessageStatusUseCase(this.repository);

  Future<void> call(
      String groupId, String messageId, Map<String, String> updatedStatus) =>
      repository.updateMessageStatus(groupId, messageId, updatedStatus);
}
