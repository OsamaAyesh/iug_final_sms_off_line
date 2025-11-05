
import '../../data/repository/chat_group_repository.dart';

class GetGroupMembersUseCase {
  final ChatGroupRepository repository;

  GetGroupMembersUseCase(this.repository);

  Future<List<Map<String, dynamic>>> call(String groupId) =>
      repository.getGroupMembers(groupId);
}