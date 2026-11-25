// ============================================================
//  config.dart — PUSAT PENGATURAN aplikasi (alamat server, dll).
//  Kalau alamat server berubah (mis. pindah ke hosting), cukup
//  ubah DI FILE INI. Semua halaman otomatis ikut, karena mereka
//  mengambil alamat lewat api_service.dart yang membaca AppConfig.
// ============================================================

// AppConfig = class biasa berisi nilai-nilai TETAP.
// "static const" = milik class (bukan milik objek), cara panggil:
//     AppConfig.apiBaseUrl
class AppConfig {
  // ---- ALAMAT API BACKEND (Laravel) KHUSUS PINTU PASIEN ----
  // Bentuk alamat: http://<IP-komputer-server>:<port>/api/pasien
  //
  //  • HP fisik, satu WiFi dengan komputer server:
  //      http://192.168.0.104:8000/api/pasien
  //    (192.168.0.104 = IP komputer tempat `php artisan serve` berjalan;
  //     cek lewat perintah `ipconfig` di Windows atau `ip a` di Linux)
  //
  //  • Emulator Android:
  //      http://10.0.2.2:8000/api/pasien
  //    (10.0.2.2 = kode khusus yang berarti "komputer saya sendiri"
  //     dilihat dari dalam emulator Android)
  //
  //  • Saat aplikasi sudah online (hosting/VPS):
  //      https://api.rsaishiyah-nganjuk.co.id/api/pasien
  //    (produksi WAJIB https, bukan http — lihat panduan bagian Keamanan)
  //
  //  PENTING — jangan lupa :8000!
  //  `php artisan serve` bawaan Laravel berjalan di port 8000, jadi alamat
  //  lengkapnya SELALU berpola: http://<IP>:8000/api/pasien
  //  Port 8000 TIDAK ditulis di sini = kesalahan pemula paling sering
  //  (aplikasi jadi "Tidak dapat terhubung ke server" padahal server hidup).
  //  (Jika nanti RS memakai Apache/Nginx di port 80, :8000 boleh dihapus.)
  static const String apiBaseUrl = 'http://rme.cihui/api/pasien';
  // static const String apiBaseUrl = 'https://rme.rsiaisyiyahnganjuk.com/api/pasien';

  // ---- Identitas aplikasi (dipakai di tampilan & judul) ----
  static const String namaAplikasi = 'E-Pasien RSIAN';
  static const String namaRumahSakit = "RSI 'Aisyiyah Nganjuk";
  static const String tagline = 'Modern  \u2022  Nyaman  \u2022  Berkesan';
}