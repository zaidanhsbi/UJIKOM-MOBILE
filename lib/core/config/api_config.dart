class ApiConfig {
  ApiConfig._();

  /// Ubah ke `true` untuk mode Online (server produksi),
  /// atau `false` untuk mode Offline / Lokal.
  /// Bisa juga di-override saat build/run: `--dart-define=IS_ONLINE=true`
  static const bool isOnline = bool.fromEnvironment(
    'IS_ONLINE',
    defaultValue: true,
  );

  /// URL server lokal / offline (127.0.0.1 untuk Windows/Web atau HP fisik via `adb reverse tcp:8000 tcp:8000`;
  /// jika pakai HP fisik via Wi-Fi, ganti ke IP LAN laptop/server lokal seperti http://192.168.1.10:8000/api)
  static const String offlineBaseUrl = 'http://127.0.0.1:8000/api';

  /// URL server online / produksi
  static const String onlineBaseUrl = 'http://apibinoexam.smkn1sumedang.sch.id/api';

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Mengembalikan URL dasar API sesuai konfigurasi lingkungan.
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    return isOnline ? onlineBaseUrl : offlineBaseUrl;
  }

  /// Mengembalikan URL origin server tanpa akhiran `/api`.
  static String get originUrl {
    if (baseUrl.endsWith('/api')) {
      return baseUrl.substring(0, baseUrl.length - 4);
    }
    return baseUrl;
  }

  /// Mengubah path gambar relatif menjadi URL lengkap berdasarkan [originUrl].
  static String resolveImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    var normalized = path.startsWith('/') ? path : '/$path';
    if (!normalized.startsWith('/storage/')) {
      normalized = '/storage$normalized';
    }
    return '$originUrl$normalized';
  }
}
