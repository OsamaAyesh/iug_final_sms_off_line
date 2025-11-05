// import 'package:telephony/telephony.dart';
// import '../model/message_model.dart';

class SendSmsUseCase {
  // final Telephony telephony = Telephony.instance;

  Future<void> sendSmsToUsers(
      List<String> phoneNumbers, String message) async {
    for (final number in phoneNumbers) {
      // await telephony.sendSms(to: number, message: message);
    }
  }
}
