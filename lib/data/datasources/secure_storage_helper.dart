import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SecureStorageHelper {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'hive_encryption_key_v1';

  static Future<HiveAesCipher> getEncryptionCipher() async {
    String? base64Key = await _storage.read(key: _keyName);

    if (base64Key == null) {
      // Buat 256-bit AES key baru dari CSPRNG jika belum ada
      final newKey = Hive.generateSecureKey();
      await _storage.write(key: _keyName, value: base64Url.encode(newKey));
      return HiveAesCipher(newKey);
    }

    final keyBytes = base64Url.decode(base64Key);
    return HiveAesCipher(keyBytes);
  }
}
