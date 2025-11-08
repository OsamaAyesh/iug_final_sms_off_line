// المسار: lib/features/home/single_chat/domain/use_cases/send_sms_use_case.dart

import '../../data/repository/single_chat_repository.dart';

class SendSingleSmsUseCase {
  final SingleChatRepository repository;

  SendSingleSmsUseCase(this.repository);

  Future<Map<String, dynamic>> call(
      String chatId, String number, String text, String messageId) =>
      repository.sendSmsToUser(chatId, number, text, messageId);
}