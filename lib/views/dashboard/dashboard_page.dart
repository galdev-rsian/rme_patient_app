// ============================================================
//  dashboard_page.dart — Halaman utama setelah login.
//  VERSI 2: header gradien RSIA dengan logo + nama pasien,
//  KARUSEL PROMOSI yang geser otomatis (media promosi),
//  GRID 12 MENU layanan pasien, bagian "Segera Hadir",
//  kartu info RS, dan tombol logout.
//  Karena ada pemutar slide otomatis (Timer), halaman ini kini
//  berubah jadi StatefulWidget (sebelumnya StatelessWidget).
// ============================================================
import 'dart:async'; // Timer untuk geser slide promosi otomatis.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../tema_rsia.dart';
import '../../models/pasien_model.dart';
import '../../services/api_service.dart'; // jembatan API (logout + badge notifikasi).
import '../auth/login_page.dart';
// Import semua halaman menu yang bisa dibuka dari dashboard ini.
import '../riwayat_pemeriksaan/riwayat_periksa_page.dart';
import 'resep_aktif_page.dart';
import 'jadwal_kontrol_page.dart';
import 'hasil_lab_page.dart';
import 'tagihan_page.dart';
import 'profil_page.dart';
// Enam modul BARU di versi 2.
import 'pendaftaran_page.dart';
import 'antrean_page.dart';
import 'telekonsultasi_page.dart';
import 'kamar_page.dart';
import 'edukasi_page.dart';
import 'notifikasi_page.dart';

class DashboardPage extends StatefulWidget {
  // Data pasien & token dikirim dari halaman login.
  final Pasien pasien;
  final String token;

  const DashboardPage({super.key, required this.pasien, required this.token});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

// Class State: menyimpan data yang berubah (posisi slide promosi) + tampilan.
class _DashboardPageState extends State<DashboardPage> {
  // ===== Pengatur karusel promosi =====
  final _promoController = PageController();
  int _promoAktif = 0;
  Timer? _promoTimer;

  // ===== Badge notifikasi (ANGKA ASLI dari server) =====
  // Diambil dari GET /notifikasi — key 'belum_baca' milik server.
  // 0 = titik merah di ikon lonceng disembunyikan.
  int _badgeNotifikasi = 0;

  // ===== DATA PROMOSI (contoh) =====
  // Daftar banner promosi RS. Tiap banner: judul, teks, ikon, 2 warna gradien.
  // Nanti data ini bisa diganti hasil fetch dari API Laravel.
  final List<Map<String, dynamic>> _promosi = [
    {'judul': 'Paket Medical Check-Up', 'teks': 'Hemat hingga 20% \u2014 berlaku sampai 31 Desember 2026.', 'ikon': Icons.monitor_heart, 'warna1': WarnaRSIA.hijau, 'warna2': WarnaRSIA.hijauTua},
    {'judul': 'Cek Kesehatan Gratis', 'teks': 'Tensi, gula darah & kolesterol gratis setiap Sabtu pagi di lobby RS.', 'ikon': Icons.volunteer_activism, 'warna1': WarnaRSIA.biru, 'warna2': WarnaRSIA.biruTua},
    {'judul': 'Konsultasi Jantung', 'teks': 'Dokter spesialis jantung praktik setiap Selasa & Kamis pagi.', 'ikon': Icons.favorite, 'warna1': Color(0xFFE8930C), 'warna2': Color(0xFFC2410C)},
    {'judul': 'IGD Siaga 24 Jam', 'teks': 'Layanan gawat darurat siap melayani Anda kapan pun.', 'ikon': Icons.emergency, 'warna1': Color(0xFFDC2626), 'warna2': Color(0xFF991B1B)},
  ];

  // ===== DAFTAR 12 MENU =====
  // Kini ditulis sebagai DAFTAR (list of map) supaya rapi & mudah
  // ditambah modul baru: tinggal tambah 1 baris di sini.
  // 'buka' berisi fungsi pembuat halamannya (tetap butuh token/pasien).
  late final List<Map<String, dynamic>> _menu = [
    // --- 6 menu asli (versi 1) ---
    {'ikon': Icons.history, 'label': 'Riwayat Periksa', 'warna': WarnaRSIA.hijau, 'buka': () => RiwayatPeriksaPage(token: widget.token)},
    {'ikon': Icons.medication, 'label': 'Resep Aktif', 'warna': WarnaRSIA.biru, 'buka': () => ResepAktifPage(token: widget.token)},
    {'ikon': Icons.calendar_today, 'label': 'Jadwal Kontrol', 'warna': Color(0xFFF59E0B), 'buka': () => JadwalKontrolPage(token: widget.token)},
    {'ikon': Icons.science, 'label': 'Hasil Lab', 'warna': Color(0xFF8B5CF6), 'buka': () => HasilLabPage(token: widget.token)},
    {'ikon': Icons.receipt_long, 'label': 'Tagihan', 'warna': WarnaRSIA.merah, 'buka': () => TagihanPage(token: widget.token)},
    {'ikon': Icons.person, 'label': 'Profil Saya', 'warna': Color(0xFF64748B), 'buka': () => ProfilPage(pasien: widget.pasien)},
    // --- 6 modul baru (versi 2) ---
    {'ikon': Icons.app_registration, 'label': 'Pendaftaran Online', 'warna': Color(0xFF0D9488), 'buka': () => PendaftaranPage(token: widget.token)},
    {'ikon': Icons.confirmation_number, 'label': 'Antrean Online', 'warna': Color(0xFFF97316), 'buka': () => AntreanPage(token: widget.token)},
    {'ikon': Icons.video_call, 'label': 'Telekonsultasi', 'warna': Color(0xFF2563EB), 'buka': () => TelekonsultasiPage(token: widget.token)},
    {'ikon': Icons.hotel, 'label': 'Ketersediaan Kamar', 'warna': Color(0xFF7C3AED), 'buka': () => KamarPage(token: widget.token)},
    {'ikon': Icons.article, 'label': 'Artikel Kesehatan', 'warna': Color(0xFFCA8A04), 'buka': () => EdukasiPage(token: widget.token)},
    {'ikon': Icons.notifications, 'label': 'Notifikasi', 'warna': Color(0xFFE11D48), 'buka': () => NotifikasiPage(token: widget.token)},
  ];

  // Fitur yang belum dibuat — ditampilkan sebagai chip "Segera Hadir".
  final List<String> _segeraHadir = ['Donor Darah', 'Surat Digital', 'Pengingat Obat', 'Asuransi & BPJS', 'Penilaian Layanan'];

  @override
  void initState() {
    super.initState();
    // Mulai pemutar slide otomatis: setiap 4 detik geser ke banner berikutnya.
    _promoTimer = Timer.periodic(const Duration(seconds: 4), (_) => _geserPromo());
    // Muat jumlah notifikasi belum dibaca dari server (GET /notifikasi).
    _muatBadgeNotifikasi();
  }

  // ===== Ambil angka "belum dibaca" dari server untuk titik merah lonceng =====
  Future<void> _muatBadgeNotifikasi() async {
    try {
      // → GET /api/pasien/notifikasi — sama endpoint dengan NotifikasiPage,
      //   hanya key 'belum_baca' yang dibaca di sini (hemat: satu endpoint,
      //   dipakai dua halaman).
      final hasil = await ApiService.get('/notifikasi');
      if (!mounted) return; // halaman bisa sudah ditutup saat menunggu jawaban.
      setState(() => _badgeNotifikasi = (hasil['belum_baca'] as num?)?.toInt() ?? 0);
    } catch (_) {
      // Gagal koneksi → biarkan badge 0, jangan mengganggu halaman utama.
    }
  }

  // Geser karusel promosi ke banner berikutnya (kembali ke 0 setelah terakhir).
  void _geserPromo() {
    if (!_promoController.hasClients) return;
    final berikutnya = (_promoAktif + 1) % _promosi.length;
    _promoController.animateToPage(berikutnya, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  // dispose WAJIB: matikan alarm & buang controller.
  @override
  void dispose() {
    _promoTimer?.cancel();
    _promoController.dispose();
    super.dispose();
  }

  // Logout: dua langkah (lihat api_service.dart):
  // 1) beri tahu server agar token dimatikan (POST /logout),
  // 2) hapus semua data tersimpan (token, nama, no. RM) lalu kembali ke login.
  Future<void> _logout(BuildContext context) async {
    await ApiService.logout(); // sudah membungkus try-catch di dalamnya.
    if (!context.mounted) return;
    // pushAndRemoveUntil dengan kondisi (_) => false artinya: buka LoginPage
    // dan BUANG SEMUA halaman di bawahnya, sehingga tombol back tidak bisa
    // kembali ke dashboard lagi (sesi benar-benar selesai).
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
    );
  }

  // Buka halaman Notifikasi lewat ikon lonceng di header.
  // .then(...) = setelah halaman ditutup dan kembali, badge dimuat ulang
  // supaya titik merah langsung akurat (mis. user baru saja menandai baca).
  void _bukaNotifikasi(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => NotifikasiPage(token: widget.token)))
        .then((_) => _muatBadgeNotifikasi());
  }

  @override
  Widget build(BuildContext context) {
    // Di dalam class State, data dari widget induk dipanggil dengan
    // awalan "widget." — contoh: widget.pasien, widget.token.
    return Scaffold(
      // TIDAK pakai AppBar biasa — header dibuat sendiri dengan gradien.
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== HEADER GRADASI: logo + nama RS + ikon + sapaan pasien =====
            Container(
              decoration: const BoxDecoration(
                gradient: gradasiRSIA,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Baris 1: logo + nama portal + ikon lonceng & logout ---
                    Row(
                      children: [
                        // Logo RSIA dalam lingkaran putih kecil.
                        Container(
                          width: 44, height: 44, padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Image.asset('assets/images/logo.png'),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // teks rata kiri.
                            children: [
                              Text('Portal Pasien RME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.5)),
                              Text("RSI 'Aisyiyah Nganjuk", style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                            ],
                          ),
                        ),
                        // Ikon lonceng + badge angka asli dari server.
                        // Titik merah + angka HANYA muncul jika _badgeNotifikasi > 0.
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(icon: const Icon(Icons.notifications_none, color: Colors.white), onPressed: () => _bukaNotifikasi(context)),
                            if (_badgeNotifikasi > 0)
                              Positioned(
                                right: 6, top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                  decoration: const BoxDecoration(color: WarnaRSIA.merah, shape: BoxShape.circle),
                                  child: Text(
                                    '$_badgeNotifikasi',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: () => _logout(context)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // --- Sapaan + nama pasien + nomor rekam medis ---
                    const Text("Assalamu'alaikum,", style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(widget.pasien.nmPasien, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    // Kapsul nomor rekam medis.
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white38)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Row hanya selebar isinya.
                        children: [
                          const Icon(Icons.badge, color: Colors.white, size: 15),
                          const SizedBox(width: 6),
                          // '$variabel' di dalam teks = menyisipkan nilai variabel
                          // (string interpolation). 'No. RM: ${pasien.noRkmMedis}'
                          Text('No. RM: ${widget.pasien.noRkmMedis}', style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== ISI HALAMAN =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ----- KARUSEL PROMOSI (media promosi di halaman utama) -----
                  const Text('Info & Promosi', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: WarnaRSIA.teksGelap)),
                  const SizedBox(height: 10),
                  // ClipRRect = MEMOTONG sudut widget anak agar melengkung
                  // (PageView tidak punya properti sudut sendiri).
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 132, // tinggi banner promosi.
                      child: PageView.builder(
                        controller: _promoController,
                        itemCount: _promosi.length,
                        onPageChanged: (index) => setState(() => _promoAktif = index),
                        itemBuilder: (context, index) {
                          final p = _promosi[index];
                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [p['warna1'] as Color, p['warna2'] as Color],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(p['ikon'] as IconData, color: Colors.white, size: 22),
                                    const SizedBox(width: 10),
                                    // Expanded + ellipsis: jika judul kepanjangan, dipotong "...".
                                    Expanded(child: Text(p['judul'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.5), overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(p['teks'] as String, style: const TextStyle(color: Colors.white, fontSize: 12.5, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Titik-titik indikator banner (aktif = lebih panjang).
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_promosi.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _promoAktif ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _promoAktif ? WarnaRSIA.hijau : WarnaRSIA.garis,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 22),
                  // ----- GRID 12 MENU LAYANAN -----
                  const Text('Layanan Pasien', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: WarnaRSIA.teksGelap)),
                  const SizedBox(height: 12),
                  // GridView.count = kotak-kotak tersusun dalam grid.
                  // shrinkWrap + NeverScrollableScrollPhysics = grid ikut di-scroll
                  // bersama halaman (bukan scroll sendiri), agar tidak "bentrok"
                  // dengan SingleChildScrollView di atasnya.
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,    // jumlah kolom.
                    crossAxisSpacing: 12, // jarak antar kolom.
                    mainAxisSpacing: 12,  // jarak antar baris.
                    // Karena label modul baru panjang (mis. "Pendaftaran Online"),
                    // rasio kotak dibuat sedikit lebih TINGGI dari persegi.
                    childAspectRatio: 0.92,
                    // .map() = ubah setiap data menu menjadi widget kotak, satu per satu.
                    children: _menu.map((m) => _menuCard(m['ikon'] as IconData, m['label'] as String, m['warna'] as Color, () {
                      // Jalankan fungsi 'buka' untuk membuat halaman tujuan,
                      // lalu tampilkan di ATAS dashboard dengan Navigator.push.
                      Navigator.push(context, MaterialPageRoute(builder: (_) => m['buka']()));
                    })).toList(),
                  ),

                  const SizedBox(height: 22),
                  // ----- BAGIAN SEGERA HADIR (ide modul berikutnya) -----
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: WarnaRSIA.garis)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.auto_awesome, color: WarnaRSIA.emas, size: 18),
                          SizedBox(width: 8),
                          Text('Segera Hadir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: WarnaRSIA.teksGelap)),
                        ]),
                        const SizedBox(height: 12),
                        // Wrap = seperti Row, tetapi item yang kepanjangan otomatis
                        // turun ke baris berikutnya (cocok untuk deretan chip).
                        Wrap(spacing: 8, runSpacing: 8, children: _segeraHadir.map((nama) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(color: WarnaRSIA.latar, borderRadius: BorderRadius.circular(999), border: Border.all(color: WarnaRSIA.garis)),
                            child: Text(nama, style: const TextStyle(fontSize: 12, color: WarnaRSIA.teksAbu, fontWeight: FontWeight.w600)),
                          );
                        }).toList()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  // ----- KARTU INFO RS (layanan darurat & jam praktik) -----
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF153F6E), Color(0xFF1E5A96)]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.emergency, color: WarnaRSIA.emas, size: 26),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('IGD Siaga 24 Jam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text('Kegawatdaruratan dilayani kapan pun.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 24), // garis pemisah tipis.
                        const Row(
                          children: [
                            Icon(Icons.schedule, color: Colors.white70, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Poliklinik: Senin\u2013Sabtu, 08.00\u201316.00 WIB', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                                  Text('Kota Nganjuk, Jawa Timur', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Footer tagline rumah sakit.
                  const Center(
                    child: Text('Modern \u2022 Nyaman \u2022 Berkesan \u2014 RSI Aisyiyah Nganjuk', style: TextStyle(color: WarnaRSIA.teksAbu, fontSize: 11.5)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method kecil pembuat SATU kotak menu, agar tidak menulis Container
  // yang sama berulang-ulang 12 kali. VoidCallback = tipe "fungsi tanpa
  // parameter dan tanpa return" (yaitu aksi ketukan).
  Widget _menuCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      // InkWell = memberi efek riak (ripple) saat diketuk, khas Android.
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: WarnaRSIA.garis),
          // Bayangan sangat tipis supaya kotak terlihat "mengambang" halus.
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // isi di tengah vertikal.
          children: [
            // Ikon menu ditempatkan dalam lingkaran berwarna muda
            // (opacity 0.12) supaya lebih hidup daripada ikon polos.
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: WarnaRSIA.teksGelap, height: 1.25)),
          ],
        ),
      ),
    );
  }
}