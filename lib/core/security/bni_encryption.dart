import 'dart:convert';
import 'dart:typed_data';

class BniEncryption {
  static const int _timeDiffLimit = 300;

  static String _getTime() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    final timeStr = (now.millisecondsSinceEpoch ~/ 1000).toString();
    return timeStr.substring(0, timeStr.length > 10 ? 10 : timeStr.length);
  }

  static String hashData(String jsonData, String cid, String secret) {
    final strRevTime = _getTime().split('').reversed.join('');
    return _doubleEncrypt('$strRevTime.$jsonData', cid, secret);
  }

  static String? parseData(String hash, String cid, String secret) {
    final parsedString = _doubleDecrypt(hash, cid, secret);
    final parts = parsedString.split('.');
    
    if (parts.length >= 2) {
      // Re-join the rest in case jsonData contained dots
      final strRevTime = parts[0];
      final jsonData = parts.sublist(1).join('.');
      
      final timeStr = strRevTime.split('').reversed.join('');
      final time = int.tryParse(timeStr);
      
      if (time != null && _tsDiff(time)) {
        return jsonData;
      }
    }
    return null;
  }

  static bool _tsDiff(int ts) {
    final currentTime = int.parse(_getTime());
    return (ts - currentTime).abs() <= _timeDiffLimit;
  }

  static String _doubleEncrypt(String text, String cid, String secret) {
    List<int> bytes = utf8.encode(text);
    bytes = _encrypt(bytes, cid);
    bytes = _encrypt(bytes, secret);

    String base64 = base64Encode(bytes);
    return base64
        .replaceAll(RegExp(r'=+$'), '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  static List<int> _encrypt(List<int> bytes, String key) {
    final result = Uint8List(bytes.length);
    final keyCodes = utf8.encode(key);
    final keyLen = keyCodes.length;

    for (var i = 0; i < bytes.length; i++) {
      final chr = bytes[i];
      final keyChr = keyCodes[(i + keyLen - 1) % keyLen];
      result[i] = (chr + keyChr) % 128;
    }
    return result;
  }

  static String _doubleDecrypt(String hash, String cid, String secret) {
    String modifiedHash = hash.replaceAll('-', '+').replaceAll('_', '/');
    
    // Add padding if needed
    final pad = (4 - (modifiedHash.length % 4)) % 4;
    modifiedHash = modifiedHash.padRight(modifiedHash.length + pad, '=');

    final bytes = base64Decode(modifiedHash);
    
    final decryptedOnce = _decrypt(bytes, secret);
    final decryptedTwice = _decrypt(decryptedOnce, cid);
    
    return utf8.decode(decryptedTwice);
  }

  static List<int> _decrypt(List<int> bytes, String key) {
    final result = Uint8List(bytes.length);
    final keyCodes = utf8.encode(key);
    final keyLen = keyCodes.length;

    for (var i = 0; i < bytes.length; i++) {
      final chr = bytes[i];
      final keyChr = keyCodes[(i + keyLen - 1) % keyLen];
      result[i] = (chr - keyChr + 128) % 128;
    }
    return result;
  }
}
