import '../../data/repository/chat_group_repository.dart';

class ToggleReactionUseCase {
  final ChatGroupRepository repository;

  ToggleReactionUseCase(this.repository);

  // Future<void> call({
  //   required String groupId,
  //   required String messageId,
  //   required String userId,
  //   required String emoji,
  // }) =>
  //     repository.toggleMessageReaction(
  //       groupId: groupId,
  //       messageId: messageId,
  //       userId: userId,
  //       emoji: emoji,
  //     );
}