// ============================================================
//  antrean_page.dart — Modul "Antrean Online".
//  Menampilkan nomor antrean pasien dan perkiraan urutan.
//
//  STATUS SINKRONISASI: BELUM ADA ENDPOINT BACKEND.
//  Ini satu-satunya modul (bersama Telekonsultasi & Kamar) yang
//  tampilannya masih DATA CONTOH — tidak ada route di routes/api.php
//  untuk antrean. Ketika backend antrean dibuat (lihat catatan
//  "CARA MENAMBAH MODUL BARU" di routes/api.php), cukup:
//    1. tulis ApiService.get('/antrean'),
//    2. ganti data contoh di bawah dengan hasil['data']
//       — polanya persis seperti riwayat_periksa_page.dart.
// ============================================================
import 'package:flutter/material.dart';
import '../../tema_rsia.dart';

class AntreanPage extends StatelessWidget {
  final String token; // token login — nanti dipakai untuk request API.

  const AntreanPage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Antrean Online')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== Kartu nomor antrean utama =====
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: BoxDecoration(
              gradient: gradasiRSIA, // gradien hijau-biru resmi RSIA.
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('Nomor Antrean Anda', style: TextStyle(color: Colors.white70, fontSize: 13.5)),
                const SizedBox(height: 8),
                // Nomor antrean besar & tebal agar mudah dibaca dari jauh.
                const Text('A-042', style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w800, letterSpacing: 2)),
                const SizedBox(height: 8),
                const Text('Poli Umum \u2014 dr. Contoh Satu', style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ===== Kartu status antrean (bertahap, seperti jejak) =====
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: WarnaRSIA.garis)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status Antrean', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: WarnaRSIA.teksGelap)),
                const SizedBox(height: 14),
                // Tiap baris = satu tahap: ikon + teks.
                _tahap(Icons.check_circle, 'Antrean diterima pukul 09.12 WIB', WarnaRSIA.hijau),
                _tahap(Icons.notifications_active, 'Saat ini dilayani: nomor A-039', WarnaRSIA.emas),
                _tahap(Icons.hourglass_top, 'Tersisa 3 antrean sebelum Anda', WarnaRSIA.biru),
                // Divider = garis pemisah tipis horizontal.
                const Divider(height: 28),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 18, color: WarnaRSIA.teksAbu),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Perkiraan dipanggil: \u00B115 menit lagi', style: TextStyle(fontSize: 13, color: WarnaRSIA.teksAbu)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ===== Tombol perbarui status (masih contoh) =====
          ElevatedButton(
            onPressed: () {
              // NANTI di sini: panggil GET /antrean dengan Bearer token,
              // lalu setState untuk mengganti angka-angka di atas.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Status terbaru: masih menunggu (contoh data).'), backgroundColor: WarnaRSIA.biru),
              );
            },
            child: const Text('Perbarui Status'),
          ),
          const SizedBox(height: 10),
          const Text('Data contoh \u2014 nomor & status nanti dari API antrean.', textAlign: TextAlign.center, style: TextStyle(color: WarnaRSIA.teksAbu, fontSize: 11.5)),
        ],
      ),
    );
  }

  // Helper pembuat SATU baris tahap status (dipakai 3 kali di atas).
  Widget _tahap(IconData ikon, String teks, Color warna) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(ikon, color: warna, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(teks, style: const TextStyle(fontSize: 13.5, color: WarnaRSIA.teksGelap))),
        ],
      ),
    );
  }
}