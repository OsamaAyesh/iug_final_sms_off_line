import '../../data/repository/chat_group_repository.dart';
import '../../data/request/send_message_request.dart';

class SendMessageUseCase {
  final ChatGroupRepository repository;

  SendMessageUseCase(this.repository);

  Future<void> call(SendMessageRequest request) =>
      repository.sendMessage(request);
}
