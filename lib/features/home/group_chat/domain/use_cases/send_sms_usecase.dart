import '../../data/repository/chat_group_repository.dart';

class SendSmsUseCase {
  final ChatGroupRepository repository;

  SendSmsUseCase(this.repository);

  Future<Map<String, int>> call(
      String groupId,
      List<String> numbers,
      String text,
      ) =>
      repository.sendSmsToUsers(groupId, numbers, text);
}