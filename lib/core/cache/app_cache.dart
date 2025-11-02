/// A class defined for cache data thats used and when close app deleted
class CacheData {
  static String email = "";

  /// Set the email to cache as a static
  static void setEmail({
    required String value,
  }) {
    email = value;
  }

  /// Get the email from the cache
  static String getEmail() {
    return email;
  }
}