import '../../domain/entities/user_session.dart';
import '../datasources/api_client.dart';
import '../datasources/secure_token_storage.dart';

class AuthRepository {
  AuthRepository(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final SecureTokenStorage _tokenStorage;

  /// Memulihkan sesi pengguna dari penyimpanan aman jika token masih tersedia.
  Future<StudentUser?> restoreSession() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) return null;
    return _tokenStorage.getUser();
  }

  /// Melakukan autentikasi siswa ke server dan menyimpan sesi secara lokal.
  Future<StudentUser> login({
    required String identifier,
    required String password,
    String? npsn,
  }) async {
    final response = await _apiClient.dio.post('/login', data: {
      if (npsn != null && npsn.trim().isNotEmpty) 'npsn': npsn.trim(),
      'username': identifier.trim(),
      'password': password,
    });

    final data = response.data as Map<String, dynamic>;
    final token = (data['token'] ?? '').toString();
    final userJson = data['user'] as Map<String, dynamic>?;

    if (token.isEmpty || userJson == null) {
      throw Exception('Respons login tidak valid.');
    }

    final user = StudentUser.fromJson(userJson);
    if (user.role != 'siswa') {
      throw Exception('Akun ini bukan akun siswa. Gunakan aplikasi sesuai peran Anda.');
    }

    await _tokenStorage.saveSession(token, user);
    return user;
  }

  /// Mengakhiri sesi pada server dan menghapus data sesi lokal.
  Future<void> logout() async {
    try {
      await _apiClient.dio.post('/logout');
    } catch (_) {
      // Tetap hapus sesi lokal meski offline
    }
    await _tokenStorage.clearSession();
  }
}
