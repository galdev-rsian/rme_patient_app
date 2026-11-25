// ============================================================
//  telekonsultasi_page.dart — Modul "Telekonsultasi".
//  Daftar dokter yang bisa dihubungi secara daring (chat/video).
//
//  STATUS SINKRONISASI: BELUM ADA ENDPOINT BACKEND.
//  Modul ini butuh layanan chat/video (bukan sekadar database),
//  mis. Firebase/Stream — lihat Ide Modul di panduan. Tampilan
//  masih DATA CONTOH dan tombol chat hanya menampilkan pesan.
// ============================================================
import 'package:flutter/material.dart';
import '../../tema_rsia.dart';

class TelekonsultasiPage extends StatelessWidget {
  final String token; // token login — nanti dipakai untuk request API.

  const TelekonsultasiPage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    // ===== DATA CONTOH dokter (nanti dari API) =====
    // 'status' menentukan apakah dokter bisa dihubungi sekarang.
    final List<Map<String, dynamic>> dokter = [
      {'nama': 'dr. Contoh Satu', 'spesialis': 'Dokter Umum', 'jadwal': 'Senin\u2013Jumat \u2022 08.00\u201312.00', 'online': true},
      {'nama': 'Sp.JP. Contoh Tujuh', 'spesialis': 'Spesialis Jantung', 'jadwal': 'Selasa & Kamis \u2022 08.00\u201312.00', 'online': true},
      {'nama': 'Sp.A. Contoh Empat', 'spesialis': 'Spesialis Anak', 'jadwal': 'Rabu \u2022 13.00\u201316.00', 'online': false},
      {'nama': 'Sp.OG. Contoh Lima', 'spesialis': 'Spesialis Kandungan', 'jadwal': 'Senin & Kamis \u2022 08.00\u201313.00', 'online': false},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Telekonsultasi')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===== Banner penjelasan di atas daftar =====
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E5A96), Color(0xFF153F6E)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.video_call, color: Colors.white, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Konsultasi tanpa datang ke RS. Pilih dokter yang sedang online, lalu mulai percakapan.',
                    style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          // ===== Daftar dokter =====
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: dokter.length, // jumlah kartu = jumlah data dokter.
              itemBuilder: (context, index) {
                final d = dokter[index];
                final online = d['online'] as bool;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: WarnaRSIA.garis)),
                  child: Row(
                    children: [
                      // CircleAvatar = lingkaran; di dalamnya huruf pertama nama dokter.
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: (d['online'] as bool) ? WarnaRSIA.hijau.withOpacity(0.14) : WarnaRSIA.garis,
                        // '$...' mengambil huruf setelah titik ('dr. Contoh Satu' → 'Contoh...').
                        child: Text(
                          (d['nama'] as String).split(' ').last.substring(0, 1),
                          style: TextStyle(color: online ? WarnaRSIA.hijauTua : WarnaRSIA.teksAbu, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['nama'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: WarnaRSIA.teksGelap)),
                            Text(d['spesialis'] as String, style: const TextStyle(fontSize: 12, color: WarnaRSIA.teksAbu)),
                            Text(d['jadwal'] as String, style: const TextStyle(fontSize: 11.5, color: WarnaRSIA.teksAbu)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Kanan: label status + tombol chat.
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Kapsul status: hijau "Online" atau abu "Offline".
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: online ? WarnaRSIA.hijau.withOpacity(0.12) : WarnaRSIA.latar,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              online ? 'Online' : 'Offline',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: online ? WarnaRSIA.hijauTua : WarnaRSIA.teksAbu),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Tombol ikon chat — aktif hanya jika dokter online.
                          IconButton(
                            onPressed: online
                                ? () {
                              // NANTI di sini: buka halaman chat dokter.
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Chat dengan ${d['nama']} segera tersedia.'), backgroundColor: WarnaRSIA.hijau),
                              );
                            }
                                : null, // null = tombol mati (dokter offline).
                            icon: const Icon(Icons.chat_bubble_outline),
                            color: online ? WarnaRSIA.hijau : WarnaRSIA.garis,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}