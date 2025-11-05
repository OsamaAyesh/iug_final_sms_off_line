import 'package:app_mobile/features/home/group_chat/domain/models/message_model.dart';

import '../../data/repository/chat_group_repository.dart';


class GetMessagesUseCase {
  final ChatGroupRepository repository;

  GetMessagesUseCase(this.repository);

  Stream<List<MessageModel>> call(String groupId) =>
      repository.getMessages(groupId);
}
