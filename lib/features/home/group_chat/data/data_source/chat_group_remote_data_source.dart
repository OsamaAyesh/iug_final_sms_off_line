import 'package:cloud_firestore/cloud_firestore.dart';
import '../request/send_message_request.dart';
import '../response/message_response.dart';

class ChatGroupRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ✅ Stream real-time messages for a specific group
  Stream<List<MessageResponse>> getMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) =>
        MessageResponse.fromJson(doc.data(), doc.id)) // pass id safely
        .toList());
  }

  /// ✅ Send a new message to Firestore
  Future<void> sendMessage(SendMessageRequest request) async {
    final messagesRef = _firestore
        .collection('groups')
        .doc(request.groupId)
        .collection('messages');

    await messagesRef.add(request.toJson());
  }

  /// ✅ Update the status (delivered, seen, failed) of a specific message
  Future<void> updateMessageStatus({
    required String groupId,
    required String messageId,
    required Map<String, String> updatedStatus,
  }) async {
    final messageRef = _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .doc(messageId);

    await messageRef.update({'status': updatedStatus});
  }

  /// ✅ (Optional) Send SMS for offline members (to be implemented later)
  Future<void> sendSmsToUsers(List<String> numbers, String text) async {
    // TODO: integrate SMS API (e.g., Twilio, Vonage)
    // This method intentionally left blank for now.
  }
}
