// ============================================================
//  onboarding_page.dart — MEDIA PROMOSI (BARU di versi 2).
//  Tampil SETELAH splash, hanya SEKALI (keberjalannya diingat di
//  SharedPreferences). Berisi 3 slide promosi layanan RS yang
//  bisa digeser, berjalan otomatis, lalu tombol "Masuk Sekarang".
//  Konten slide adalah CONTOH — nanti bisa diambil dari API RS.
// ============================================================

import 'dart:async'; // Timer untuk geser slide otomatis.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../tema_rsia.dart';
import '../auth/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  // PageController = "remote control" untuk PageView: bisa memerintahkan
  // halaman geser ke posisi tertentu (animateToPage / nextPage).
  final _pageController = PageController();

  int _halamanAktif = 0; // slide yang sedang terlihat (0, 1, atau 2).
  Timer? _timer;         // Timer? = boleh KOSONG (belum dibuat / sudah dimatikan).

  // ===== DATA SLIDE PROMOSI (contoh) =====
  // Map = "kotak berisi pasangan kunci-nilai" seperti JSON.
  // Tiap slide punya: judul, teks, ikon, dan 2 warna gradien.
  final List<Map<String, dynamic>> _promosi = [
    {
      'judul': 'Paket Medical Check-Up',
      'teks': 'Hemat hingga 20% untuk pemeriksaan kesehatan menyeluruh. Cocok untuk persiapan menikah, kerja, dan rutin tahunan.',
      'ikon': Icons.monitor_heart,
      'warna1': Color(0xFF00A651),
      'warna2': Color(0xFF007A3D),
    },
    {
      'judul': 'Konsultasi Dokter Spesialis',
      'teks': 'Jadwal dokter spesialis jantung, anak, kandungan, dan gigi bisa dilihat kapan saja — plus layanan telekonsultasi.',
      'ikon': Icons.medical_services,
      'warna1': Color(0xFF1E5A96),
      'warna2': Color(0xFF153F6E),
    },
    {
      'judul': 'Satu Aplikasi untuk Semua Layanan',
      'teks': 'Pendaftaran online, antrean, hasil lab, resep obat, hingga tagihan — semuanya dalam genggaman Anda.',
      'ikon': Icons.apps,
      'warna1': Color(0xFFF2B705),
      'warna2': Color(0xFFE8930C),
    },
  ];

  // initState: pasang pemutar slide OTOMATIS (setiap 4 detik pindah slide).
  @override
  void initState() {
    super.initState();
    // Timer.periodic = alarm yang BERULANG setiap selang waktu tertentu.
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _geserOtomatis());
  }

  // Fungsi yang dijalankan alarm setiap 4 detik: geser ke slide berikutnya.
  void _geserOtomatis() {
    // hasClients = "apakah PageView sudah siap di layar?". Kalau belum
    // siap (masih animasi buka), lewati dulu supaya tidak error.
    if (!_pageController.hasClients) return;
    final berikutnya = (_halamanAktif + 1) % _promosi.length; // % = kembali ke 0 setelah slide terakhir.
    _pageController.animateToPage(
      berikutnya,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut, // gaya gerakan: mulai lambat-cepat-lambat.
    );
  }

  // dispose WAJIB: matikan alarm dan buang controller supaya tidak
  // terjadi kebocoran memori (aturan baku di StatefulWidget).
  @override
  void dispose() {
    _timer?.cancel(); // tanda ?. = "panggil HANYA jika timer tidak kosong".
    _pageController.dispose();
    super.dispose();
  }

  // Dipanggil saat user menekan tombol "Lewati" atau "Masuk Sekarang".
  Future<void> _selesaiOnboarding() async {
    _timer?.cancel(); // matikan dulu alarm geser otomatis.
    final sp = await SharedPreferences.getInstance();
    // Simpan penanda TRUE → aplikasi berikutnya langsung ke login
    // (media promosi tidak mengganggu lagi setiap kali dibuka).
    await sp.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== Baris atas: label + tombol Lewati =====
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Info & Promosi RSIA', style: TextStyle(color: WarnaRSIA.teksAbu, fontSize: 13, fontWeight: FontWeight.w600)),
                  // TextButton = tombol tanpa kotak (hanya teks).
                  TextButton(
                    onPressed: _selesaiOnboarding,
                    child: const Text('Lewati', style: TextStyle(color: WarnaRSIA.teksAbu, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // ===== Slide promosi yang bisa digeser =====
            // Expanded = "isi seluruh sisa ruang vertikal yang tersisa".
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _promosi.length, // jumlah slide = panjang daftar promosi.
                // onPageChanged = dijalankan saat slide berpindah; index = slide baru.
                // Karena _halamanAktif berubah → WAJIB dibungkus setState agar
                // titik-titik indikator di bawah ikut berubah warna/lebar.
                onPageChanged: (index) => setState(() => _halamanAktif = index),
                itemBuilder: (context, index) {
                  final p = _promosi[index];
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      decoration: BoxDecoration(
                        // Gradien warna diambil dari data slide ("p['warna1']"
                        // adalah Color, jadi perlu dikonversi: p['warna1'] as Color).
                        gradient: LinearGradient(
                          colors: [p['warna1'] as Color, p['warna2'] as Color],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28), // sudut melengkung besar.
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(p['ikon'] as IconData, color: Colors.white, size: 64),
                          const SizedBox(height: 20),
                          Text(p['judul'] as String, textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Text(p['teks'] as String, textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ===== Titik-titik indikator slide =====
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // di tengah horizontal.
              children: List.generate(_promosi.length, (i) {
                // List.generate(n, f) = membuat daftar berisi hasil fungsi f, sebanyak n.
                // AnimatedContainer = Container yang PERUBAHANNYA dianimasikan
                // otomatis (lebar titik aktif 26, titik lain 8).
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _halamanAktif ? 26 : 8, // titik aktif lebih panjang.
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _halamanAktif ? WarnaRSIA.hijau : WarnaRSIA.garis,
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // ===== Tombol bawah: Lanjut / Masuk Sekarang =====
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  // Di slide TERAKHIR tulisannya berubah jadi "Masuk Sekarang".
                  backgroundColor: _halamanAktif == _promosi.length - 1 ? WarnaRSIA.hijau : WarnaRSIA.biru,
                ),
                onPressed: () {
                  if (_halamanAktif == _promosi.length - 1) {
                    // Slide terakhir → selesai, menuju halaman login.
                    _selesaiOnboarding();
                  } else {
                    // Belum slide terakhir → geser manual ke slide berikutnya.
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Text(_halamanAktif == _promosi.length - 1 ? 'Masuk Sekarang' : 'Lanjut'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}