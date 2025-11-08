// المسار: lib/features/home/single_chat/domain/use_cases/send_message_use_case.dart

import '../../data/repository/single_chat_repository.dart';
import '../../data/request/send_message_request.dart';

class SendSingleMessageUseCase {
  final SingleChatRepository repository;

  SendSingleMessageUseCase(this.repository);

  Future<void> call(SendSingleMessageRequest request) =>
      repository.sendMessage(request);
}