# BinoExam Mobile / Client App (Flutter)

Aplikasi ujian siswa berbasis Flutter dengan dukungan **semi-offline** (soal diunduh ke penyimpanan lokal SQLite dan jawaban otomatis disimpan sebagai *Pending Sync* jika koneksi terputus).

---

## 1. Prerequisites (Yang Harus Di-download)

- **Flutter SDK** (disarankan versi stabil terbaru, minimal Dart 3.x): https://docs.flutter.dev/get-started/install
- **Android Studio / Android SDK** (untuk build APK atau run ke perangkat Android)
- **Git**: https://git-scm.com/downloads
- *(Opsional)* **ADB (Android Debug Bridge)** — sudah termasuk di Android SDK Platform-Tools, untuk koneksi HP fisik via kabel USB.

Cek instalasi dengan menjalankan:
```powershell
flutter doctor
```

---

## 2. Langkah-langkah Instalasi

1. Masuk ke folder `app`:
   ```powershell
   cd app
   ```
2. Install seluruh dependency Flutter:
   ```powershell
   flutter pub get
   ```
3. Pastikan backend Laravel (`dashboard/be`) sudah berjalan terlebih dahulu.

---

## 3. Konfigurasi

Seluruh konfigurasi URL API berada di `lib/core/config/api_config.dart`:

```dart
static const bool isOnline = bool.fromEnvironment(
  'IS_ONLINE',
  defaultValue: false,
);

static const String offlineBaseUrl = 'http://127.0.0.1:8000/api';
static const String onlineBaseUrl = 'https://domainanda/api';
```

- Ubah `onlineBaseUrl` sesuai domain API server produksi Anda.
- Ubah `offlineBaseUrl` jika menggunakan IP LAN server lokal (misal `http://192.168.1.10:8000/api`).

---

## 4. Menjalankan Mode Offline (Lokal) vs Online (Produksi)

### A. Mode Offline / Lokal (`isOnline = false`)
1. Jalankan backend Laravel dengan host `0.0.0.0`:
   ```powershell
   cd dashboard/be
   php artisan serve --host=0.0.0.0 --port=8000
   ```
2. Pilih cara menjalankan Flutter sesuai perangkat:
   - **Windows / Chrome:**
     ```powershell
     flutter run
     ```
   - **HP Fisik via Kabel USB:**
     ```powershell
     adb reverse tcp:8000 tcp:8000
     flutter run
     ```
   - **HP Fisik via Wi-Fi (1 jaringan dengan laptop/server):**
     ```powershell
     flutter run --dart-define=API_BASE_URL=http://IP_LAPTOP_ANDA:8000/api
     ```
     *(Cek IP laptop dengan perintah `ipconfig`.)*

### B. Mode Online / Produksi (`IS_ONLINE=true`)
- **Run langsung:**
  ```powershell
  flutter run --dart-define=IS_ONLINE=true
  ```
- **Build APK rilis untuk dibagikan ke siswa:**
  ```powershell
  flutter build apk --release --dart-define=IS_ONLINE=true
  ```

  *(Atau override URL langsung saat build: `flutter build apk --release --dart-define=API_BASE_URL=https://api.domainanda.com/api`.)*
