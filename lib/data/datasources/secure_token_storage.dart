import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/user_session.dart';

/// Penyimpanan aman untuk token JWT & sesi pengguna menggunakan FlutterSecureStorage
/// (Android Keystore) — bukan SharedPreferences.
class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'binoexam_jwt_token';
  static const _userKey = 'binoexam_user_json';

  /// Menyimpan token JWT dan data pengguna ke penyimpanan aman.
  Future<void> saveSession(String token, StudentUser user) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  /// Mengambil token JWT yang tersimpan, atau `null` jika belum ada.
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  /// Mengambil data pengguna yang tersimpan, atau `null` jika tidak valid/kosong.
  Future<StudentUser?> getUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return StudentUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Menghapus token JWT dan data pengguna dari penyimpanan aman.
  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
