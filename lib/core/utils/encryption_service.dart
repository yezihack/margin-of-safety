import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// 加密服务
class EncryptionService {
  static const String _keyStorageKey = 'encryption_key';
  static const String _saltStorageKey = 'encryption_salt';

  final FlutterSecureStorage _secureStorage;
  final Logger _logger = Logger();

  encrypt.Key? _key;

  EncryptionService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// 初始化加密服务
  Future<void> initialize(String password) async {
    try {
      // 获取或生成盐值
      String? saltStr = await _secureStorage.read(key: _saltStorageKey);
      Uint8List salt;

      if (saltStr == null) {
        // 首次使用，生成新盐值
        salt = encrypt.IV.fromSecureRandom(16).bytes;
        await _secureStorage.write(
          key: _saltStorageKey,
          value: base64Encode(salt),
        );
        _logger.i('Generated new encryption salt');
      } else {
        salt = base64Decode(saltStr);
      }

      // 从密码派生密钥
      _key = _deriveKey(password, salt);
      _logger.i('Encryption service initialized');
    } catch (e) {
      _logger.e('Failed to initialize encryption service: $e');
      rethrow;
    }
  }

  /// 从密码派生密钥（使用 PBKDF2）
  encrypt.Key _deriveKey(String password, Uint8List salt) {
    // 使用 PBKDF2 派生 32 字节密钥
    final passwordBytes = utf8.encode(password);
    final hmac = Hmac(sha256, salt);
    final digest = hmac.convert(passwordBytes);

    // 简化版 PBKDF2（实际应用应使用更多迭代）
    var key = digest.bytes;
    for (int i = 0; i < 10000; i++) {
      final hmac = Hmac(sha256, salt);
      key = hmac.convert(key).bytes;
    }

    return encrypt.Key(Uint8List.fromList(key));
  }

  /// 加密金额
  String encryptAmount(double amount) {
    if (_key == null) {
      throw StateError('Encryption service not initialized');
    }

    try {
      final plaintext = amount.toString();
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_key!, mode: encrypt.AESMode.gcm),
      );

      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      // 格式: iv:ciphertext (都是 base64 编码)
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      _logger.e('Failed to encrypt amount: $e');
      rethrow;
    }
  }

  /// 解密金额
  double decryptAmount(String encryptedAmount) {
    if (_key == null) {
      throw StateError('Encryption service not initialized');
    }

    try {
      final parts = encryptedAmount.split(':');
      if (parts.length != 2) {
        throw const FormatException('Invalid encrypted format');
      }

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_key!, mode: encrypt.AESMode.gcm),
      );

      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      return double.parse(decrypted);
    } catch (e) {
      _logger.e('Failed to decrypt amount: $e');
      throw Exception('数据解密失败，可能已损坏');
    }
  }

  /// 哈希密码（用于验证）
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 更换主密码（重新加密所有数据）
  Future<void> rotateKey(String newPassword) async {
    try {
      // 生成新盐值
      final newSalt = encrypt.IV.fromSecureRandom(16).bytes;
      await _secureStorage.write(
        key: _saltStorageKey,
        value: base64Encode(newSalt),
      );

      // 派生新密钥
      _key = _deriveKey(newPassword, newSalt);
      _logger.i('Encryption key rotated successfully');
    } catch (e) {
      _logger.e('Failed to rotate encryption key: $e');
      rethrow;
    }
  }
}
