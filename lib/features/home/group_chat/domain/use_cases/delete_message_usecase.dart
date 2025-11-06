import '../../data/repository/chat_group_repository.dart';

class DeleteMessageUseCase {
  final ChatGroupRepository repository;

  DeleteMessageUseCase(this.repository);

  // Future<void> call({
  //   required String groupId,
  //   required String messageId,
  //   required String userId,
  //   required bool isAdmin,
  // }) =>
  //     repository.deleteMessage(
  //       groupId: groupId,
  //       messageId: messageId,
  //       userId: userId,
  //       isAdmin: isAdmin,
  //     );
}