// ============================================================
//  splash_screen.dart — HALAMAN PEMBUKA (splash). BARU di versi 2.
//  Tampil ±3 detik saat aplikasi dibuka: logo RSIA + nama RS +
//  tagline "Modern • Nyaman • Berkesan" + animasi muncul lembut.
//  Setelah itu otomatis pindah ke:
//    - OnboardingPage (media promosi) jika BELUM pernah dibuka, atau
//    - LoginPage jika sudah pernah (disimpan di SharedPreferences).
// ============================================================

// dart:async = bawaan Dart, berisi Timer (pewaktu/alarm) yang kita
// pakai untuk "menunggu 3 detik lalu pindah halaman".
import 'dart:async';
import 'package:flutter/material.dart';
// Untuk membaca/menyimpan penanda kecil (onboarding sudah dilihat atau belum).
import 'package:shared_preferences/shared_preferences.dart';
import '../../tema_rsia.dart'; // warna & gradien resmi RSIA.
import 'onboarding_page.dart'; // halaman media promosi (slide geser).
import '../auth/login_page.dart'; // halaman login (tujuan akhir).

// StatefulWidget karena splash punya "peristiwa waktu" (3 detik lalu pindah).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // initState() = dijalankan SEKALI saat halaman PERTAMA kali dibuat.
  // Tempat yang tepat untuk memasang pewaktu (Timer).
  @override
  void initState() {
    super.initState();
    // Timer(duration, fungsi) = "alarm": setelah 3 detik, jalankan _bukaBerikutnya.
    Timer(const Duration(seconds: 3), _bukaBerikutnya);
  }

  // Future<void> + async karena di dalamnya ada proses "menunggu"
  // (membaca penyimpanan HP) yang tidak boleh membekukan tampilan.
  Future<void> _bukaBerikutnya() async {
    // Ambil "kotak penyimpanan kecil" di HP.
    final sp = await SharedPreferences.getInstance();
    // getBool('onboarding_done') = baca penanda true/false.
    // "?? false" = kalau penandanya belum pernah disimpan, anggap false
    // (artinya: media promosi belum pernah ditampilkan → harus ditampilkan).
    final sudahLihatPromosi = sp.getBool('onboarding_done') ?? false;

    // mounted = "apakah halaman ini masih terbuka?". WAJIB dicek setelah
    // await, karena selama menunggu user bisa saja menutup aplikasi.
    if (!mounted) return;

    if (sudahLihatPromosi) {
      // Sudah pernah melihat promosi → langsung ke halaman login.
      // pushReplacement = ganti halaman (splash DIHAPUS, tidak bisa "back" ke sini).
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      // Belum pernah → tampilkan media promosi (onboarding) dulu.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold = "kanvas" standar satu halaman. Body-nya satu Container
    // gradien hijau-biru yang memenuhi seluruh layar.
    return Scaffold(
      body: Container(
        // decoration = "dekorasi" wadah: di sini dipakai gradien resmi RSIA
        // (hijau → biru) yang didefinisikan di tema_rsia.dart.
        decoration: const BoxDecoration(gradient: gradasiRSIA),
        width: double.infinity, // penuhi lebar layar.
        child: SafeArea(
          // SafeArea = isi tidak menempel di belakang notch/status bar HP.
          child: Column(
            // Column = menyusun widget dari ATAS ke BAWAH.
            mainAxisAlignment: MainAxisAlignment.center, // semuanya di tengah.
            children: [
              // TweenAnimationBuilder = widget ANIMASI praktis: "animasikan
              // suatu nilai dari angka awal ke angka akhir selama durasi tertentu".
              // Di sini nilainya 0.0 → 1.0 dipakai untuk transparansi & ukuran,
              // sehingga logo dan teks MUNCUL PERLAHAN (fade in + membesar).
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1), // nilai dari 0 ke 1.
                duration: const Duration(milliseconds: 900), // selama 0,9 detik.
                builder: (context, nilai, anak) {
                  // builder dipanggil Flutter berkali-kali selama animasi,
                  // dengan "nilai" yang berubah 0 → 1. Kita pakai nilainya:
                  return Opacity(
                    opacity: nilai, // transparansi 0% → 100%.
                    child: Transform.scale(
                      scale: 0.8 + (0.2 * nilai), // ukuran 80% → 100%.
                      child: anak, // widget yang dianimasikan (dibawah).
                    ),
                  );
                },
                // child = isi yang dianimasikan (dipindah ke sini agar TIDAK
                // dibangun ulang setiap frame — teknik hemat performa).
                child: Column(
                  children: [
                    // Lingkaran putih berisi LOGO RSIA dari file assets.
                    // Image.asset = ambil gambar dari folder assets/images/
                    // (folder harus didaftarkan di pubspec.yaml, lihat Bagian 3).
                    Container(
                      width: 130,
                      height: 130,
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle, // bentuk lingkaran.
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 18)],
                      ),
                      child: Image.asset('assets/images/logo.png'),
                    ),
                    const SizedBox(height: 18), // jarak kosong 18px.
                    const Text(
                      "RSI 'Aisyiyah Nganjuk",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4, // jarak antar huruf sedikit dilebarkan.
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Kapsul tagline: kotak bulat semi-transparan berisi teks.
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15), // putih transparan.
                        borderRadius: BorderRadius.circular(999), // sudut = kapsul.
                        border: Border.all(color: Colors.white38),
                      ),
                      child: const Text(
                        'Modern  \u2022  Nyaman  \u2022  Berkesan', // \u2022 = tanda •
                        style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600, letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 46),
              // Lingkaran kecil yang berputar — tanda "aplikasi sedang menyiapkan".
              const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              const SizedBox(height: 30),
              const Text(
                'Portal Pasien RME v2.0',
                style: TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}