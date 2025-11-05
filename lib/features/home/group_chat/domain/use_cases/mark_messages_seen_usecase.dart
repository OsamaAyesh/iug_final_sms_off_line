import '../../data/repository/chat_group_repository.dart';

class MarkMessagesSeenUseCase {
  final ChatGroupRepository repository;

  MarkMessagesSeenUseCase(this.repository);

  Future<void> call({
    required String groupId,
    required String userId,
  }) =>
      repository.markMessagesAsSeen(
        groupId: groupId,
        userId: userId,
      );
}