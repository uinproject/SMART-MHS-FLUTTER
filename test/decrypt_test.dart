import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Decrypt keys', () {
    final password = 'jangandimakansendiri';
    final apiKeysEnc = '/5kxj6gyUOPYsfTRPzSo9Fe9S5JDA0YLL+Eif3ok0a0=';
    final userPassEnc = 'xLM86CfnBeiQiQcNc3sVUpNXbVgVebRBc1j3mnx8KgDZG3rq8oqhKtVchv2e+6wL';

    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = Key(Uint8List.fromList(keyBytes));
    final zeroIv = IV(Uint8List(16));

    final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

    try {
      final decryptedApiKeys = encrypter.decrypt64(apiKeysEnc, iv: zeroIv);
      print('API_KEYS: $decryptedApiKeys');
    } catch (e) {
      print('Error decrypting API_KEYS: $e');
    }

    try {
      final decryptedUserPass = encrypter.decrypt64(userPassEnc, iv: zeroIv);
      print('USER_PASS: $decryptedUserPass');
    } catch (e) {
      print('Error decrypting USER_PASS: $e');
    }
  });
}
