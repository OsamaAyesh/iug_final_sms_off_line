// المسار: lib/features/home/single_chat/domain/use_cases/get_or_create_chat_use_case.dart

import '../../data/repository/single_chat_repository.dart';

class GetOrCreateChatUseCase {
  final SingleChatRepository repository;

  GetOrCreateChatUseCase(this.repository);

  Future<String> call(String user1Id, String user2Id) =>
      repository.getOrCreateChatId(user1Id, user2Id);
}