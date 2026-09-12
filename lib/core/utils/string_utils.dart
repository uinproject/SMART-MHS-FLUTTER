class StringUtils {
  /// Sensor/mask email address for privacy and security dynamically based on username length.
  /// Examples:
  /// - 'a@gmail.com' -> '*@gmail.com'
  /// - 'li@gmail.com' -> 'l*@gmail.com'
  /// - 'lin@gmail.com' -> 'l**@gmail.com'
  /// - 'john@gmail.com' -> 'jo**@gmail.com'
  /// - 'ahmad@gmail.com' -> 'ah***@gmail.com'
  /// - 'santoso@gmail.com' -> 'san****@gmail.com'
  /// - 'ayubhacked2169@gmail.com' -> 'ayub**********@gmail.com'
  static String maskEmail(String? email) {
    if (email == null || email.isEmpty) return '';
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    if (username.isEmpty) return email;

    int visibleCount;
    if (username.length <= 1) {
      return '*@$domain';
    } else if (username.length <= 3) {
      // e.g. 'li' -> 'l*', 'lin' -> 'l**'
      visibleCount = 1;
    } else if (username.length <= 5) {
      // e.g. 'john' -> 'jo**', 'ahmad' -> 'ah***'
      visibleCount = 2;
    } else if (username.length <= 9) {
      // e.g. 'santoso' -> 'san****'
      visibleCount = 3;
    } else {
      // e.g. 'ayubhacked2169' -> 'ayub**********'
      visibleCount = 4;
    }

    final visible = username.substring(0, visibleCount);
    final masked = '*' * (username.length - visibleCount);
    return '$visible$masked@$domain';
  }
}
