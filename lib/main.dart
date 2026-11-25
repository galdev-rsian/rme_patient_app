// ============================================================
//  main.dart — TITIK MASUK (pintu masuk) aplikasi Flutter.
//  Setiap aplikasi Flutter WAJIB punya file main.dart karena
//  di sinilah program pertama kali dijalankan.
//  VERSI 2: tema sekarang memakai warna resmi RSIA (tema_rsia.dart)
//  dan halaman pertama adalah SPLASH (pembuka) lalu MEDIA PROMOSI.
// ============================================================

// "import" artinya: ambil kode dari file/package lain agar bisa dipakai di sini.
// 'package:flutter/material.dart' = bawaan Flutter, berisi semua widget tampilan
// (Text, Tombol, AppBar, dll). Wajib ada di setiap file yang berisi tampilan.
import 'package:flutter/material.dart';

// Tema warna resmi RSIA (hijau, biru, emas) — didefinisikan di tema_rsia.dart.
import 'tema_rsia.dart';
// Alamat API server kini berada di file services/config.dart
// (AppConfig.apiBaseUrl). Cara pakainya lewat lib/services/api_service.dart.
import 'services/config.dart';
// Halaman pembuka (splash) — sekarang jadi halaman PERTAMA aplikasi.
import 'views/intro/splash_screen.dart';

// void main() = fungsi yang PERTAMA KALI dijalankan saat aplikasi dibuka.
void main() {
  // runApp() memberi tahu Flutter: "inilah widget paling atas aplikasi kita".
  // const = nilai sudah tetap sejak awal (lebih hemat memori).
  runApp(const RmeApp());
}

// ===== ALAMAT API sudah pindah =====
// Dulu: const String apiBaseUrl = 'http://192.168.0.104:8000/api/pasien';
// Sekarang tinggal di file lib/services/config.dart supaya satu tempat
// dengan pengaturan lain (jangan lupa :8000 — port php artisan serve),
// dan halaman menu memanggil server lewat lib/services/api_service.dart
// (ApiService.get / ApiService.post).
// Halaman lama yang masih menulis http.post sendiri (login & ganti
// password) memakai: import '../../services/config.dart';

// RmeApp = widget AKAR (paling atas) aplikasi.
// StatelessWidget = widget yang TIDAK punya data berubah-ubah (tampilannya statis).
class RmeApp extends StatelessWidget {
  // {super.key} = pola bawaan Flutter: meneruskan "key" (identitas widget)
  // ke class induk. Untuk pemula: cukup selalu tulis persis seperti ini.
  const RmeApp({super.key});

  // build() = method WAJIB di semua widget; isinya deskripsi TAMPILANNYA.
  // context = "posisi" widget ini di pohon widget (untuk navigasi, tema, dll).
  @override
  Widget build(BuildContext context) {
    // MaterialApp = kerangka dasar aplikasi: mengatur tema, navigasi, dan home.
    return MaterialApp(
      // Judul aplikasi diambil dari config.dart (ubah sekali, semua ikut).
      title: '${AppConfig.namaAplikasi} ${AppConfig.namaRumahSakit}',
      // Menyembunyikan tulisan "DEBUG" di pojok kanan atas saat development.
      debugShowCheckedModeBanner: false,

      // ThemeData = pengaturan gaya visual GLOBAL: warna utama, bentuk input,
      // bentuk tombol, dll. Karena diatur DI SINI, semua halaman otomatis
      // seragam tanpa perlu mengatur satu per satu (prinsip tema global).
      theme: ThemeData(
        // Membuat palet warna otomatis dari warna benih HIJAU RSIA.
        colorScheme: ColorScheme.fromSeed(seedColor: WarnaRSIA.hijau),
        useMaterial3: true, // pakai desain Material 3 (versi terbaru dari Google).

        // Latar halaman bawaan semua Scaffold: abu sangat muda kehijauan.
        scaffoldBackgroundColor: WarnaRSIA.latar,

        // Gaya bawaan SEMUA AppBar di seluruh aplikasi: hijau RSIA, teks putih,
        // tanpa bayangan. Karena ini, halaman-halaman menu TIDAK PERLU lagi
        // menulis backgroundColor di AppBar-nya masing-masing.
        appBarTheme: const AppBarTheme(
          backgroundColor: WarnaRSIA.hijau,
          foregroundColor: Colors.white, // warna teks & ikon di AppBar.
          elevation: 0,                  // tanpa bayangan (tampilan lebih flat/modern).
          centerTitle: false,            // judul rata kiri (gaya modern).
          titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
        ),

        // Gaya bawaan untuk SEMUA kotak input (TextFormField) di seluruh aplikasi.
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white, // isi kotak input putih bersih.
          // Bentuk bingkai melengkung 12px — terlihat lebih lembut & modern.
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: WarnaRSIA.garis)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: WarnaRSIA.garis)),
          // Saat kotak input sedang aktif diketik, bingkainya jadi HIJAU RSIA.
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: WarnaRSIA.hijau, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),

        // Gaya bawaan SEMUA tombol naik (ElevatedButton) di seluruh aplikasi:
        // hijau RSIA, tinggi 52, sudut melengkung 14, teks tebal putih.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: WarnaRSIA.hijau,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52), // lebar penuh, tinggi 52.
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),

      // home = halaman PERTAMA yang tampil saat aplikasi dibuka.
      // Sekarang bukan login lagi, tapi SPLASH (pembuka + logo RSIA),
      // lalu splash otomatis melanjutkan ke Media Promosi (onboarding).
      home: const SplashScreen(),
    );
  }
}