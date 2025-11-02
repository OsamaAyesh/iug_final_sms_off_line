import 'package:app_mobile/core/extensions/extensions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Class defined for env service to fetch values
class EnvService {
  static String getString({
    required String key,
  }) {
    return dotenv.env[key].onNull();
  }

  static Future<bool> getBool({
    required String key,
  }) async =>
      dotenv.env[key].onNullBool();
}
