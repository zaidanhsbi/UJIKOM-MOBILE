import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/api_client.dart';
import '../../data/datasources/exam_local_storage.dart';
import '../../data/datasources/secure_token_storage.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/exam_repository.dart';
import '../../domain/entities/user_session.dart';

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage();
});

final examLocalStorageProvider = Provider<ExamLocalStorage>((ref) {
  return ExamLocalStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(secureTokenStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureTokenStorageProvider),
  );
});

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return ExamRepository(
    ref.watch(apiClientProvider),
    ref.watch(examLocalStorageProvider),
  );
});

class AuthState {
  const AuthState({
    this.initialized = false,
    this.loading = false,
    this.user,
    this.error,
  });

  final bool initialized;
  final bool loading;
  final StudentUser? user;
  final String? error;

  /// Mengembalikan `true` jika pengguna sudah terautentikasi.
  bool get isAuthenticated => user != null;

  /// Membuat salinan [AuthState] dengan nilai field yang diperbarui.
  AuthState copyWith({
    bool? initialized,
    bool? loading,
    StudentUser? user,
    bool clearUser = false,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      initialized: initialized ?? this.initialized,
      loading: loading ?? this.loading,
      user: clearUser ? null : (user ?? this.user),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState()) {
    _restore();
  }

  final AuthRepository _repo;

  /// Memulihkan sesi pengguna secara otomatis saat provider diinisialisasi.
  Future<void> _restore() async {
    final user = await _repo.restoreSession();
    state = state.copyWith(initialized: true, user: user);
  }

  /// Melakukan login siswa dan memperbarui state autentikasi.
  Future<bool> login({
    required String identifier,
    required String password,
    String? npsn,
  }) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final user = await _repo.login(
        identifier: identifier,
        password: password,
        npsn: npsn,
      );
      state = state.copyWith(loading: false, initialized: true, user: user);
      return true;
    } catch (e) {
      final msg = ApiClient.extractErrorMessage(
        e,
        fallback: e.toString().replaceFirst('Exception: ', ''),
      );
      state = state.copyWith(loading: false, error: msg);
      return false;
    }
  }

  /// Melakukan logout dan menghapus state pengguna yang sedang aktif.
  Future<void> logout() async {
    await _repo.logout();
    state = state.copyWith(clearUser: true, clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
