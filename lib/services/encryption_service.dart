import 'dart:typed_data';
import 'dart:io';
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  // 使用正确的AES-256密钥和IV长度
  static const String _keyBase64 =
      'hm8Sdnov964Zg8cjQP9nBEqShWAKtHpC+shcYm2UPqQ='; // 32字节 = 256位
  static const String _ivBase64 = 'DsPexkdOzsbzK0krUDigsA=='; // 16字节 = 128位

  static final _key = Key.fromBase64(_keyBase64);
  static final _iv = IV.fromBase64(_ivBase64);
  static final _encrypter = Encrypter(AES(_key));

  /// 加密字符串
  static String encryptString(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  /// 解密字符串
  static String decryptString(String encryptedText) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedText);
      final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
      return decrypted;
    } catch (e) {
      throw Exception('解密失败: $e');
    }
  }

  /// 加密字节数据
  static Uint8List encryptBytes(Uint8List data) {
    final encrypted = _encrypter.encryptBytes(data, iv: _iv);
    return encrypted.bytes;
  }

  /// 解密字节数据
  static Uint8List decryptBytes(Uint8List encryptedData) {
    try {
      final encrypted = Encrypted(encryptedData);
      final decrypted = _encrypter.decryptBytes(encrypted, iv: _iv);
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw Exception('解密失败: $e');
    }
  }

  /// 检查文件是否为加密备份文件
  static bool isEncryptedBackupFile(String filePath) {
    return filePath.toLowerCase().endsWith('.drmbak');
  }

  /// 检查文件是否为普通JSON备份文件
  static bool isJsonBackupFile(String filePath) {
    return filePath.toLowerCase().endsWith('.json');
  }

  /// 检查文件是否为压缩包备份文件
  static bool isZipBackupFile(String filePath) {
    return filePath.toLowerCase().endsWith('.zip');
  }

  /// 加密图片文件
  static Future<Uint8List> encryptImageFile(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('图片文件不存在: $imagePath');
      }

      final imageBytes = await file.readAsBytes();
      return encryptBytes(imageBytes);
    } catch (e) {
      throw Exception('加密图片失败: $e');
    }
  }

  /// 解密图片文件
  static Future<Uint8List> decryptImageFile(
    Uint8List encryptedImageData,
  ) async {
    try {
      return decryptBytes(encryptedImageData);
    } catch (e) {
      throw Exception('解密图片失败: $e');
    }
  }
}
