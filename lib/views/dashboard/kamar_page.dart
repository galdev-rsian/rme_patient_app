// ============================================================
//  kamar_page.dart — Modul "Ketersediaan Kamar".
//  Informasi tempat tidur tersedia per kelas, lengkap dengan
//  bar progres.
//
//  STATUS SINKRONISASI: BELUM ADA ENDPOINT BACKEND.
//  Data bed/occupancy memang sudah ada di SIMRS, tetapi belum ada
//  route-nya di routes/api.php. Ketika dibuat (pola PasienLabController:
//  query tabel SIMRS → balas { status, message, data }), ganti data
//  contoh di bawah dengan ApiService.get('/kamar') — pola sama seperti
//  riwayat_periksa_page.dart.
// ============================================================
import 'package:flutter/material.dart';
import '../../tema_rsia.dart';

class KamarPage extends StatelessWidget {
  final String token; // token login — nanti dipakai untuk request API.

  const KamarPage({super.key, required this.token});

  // Helper menentukan warna berdasarkan sisa kamar yang tersedia.
  Color _warnaStatus(int tersedia) {
    if (tersedia == 0) return WarnaRSIA.merah;  // penuh → merah.
    if (tersedia <= 3) return WarnaRSIA.emas;   // hampir penuh → emas.
    return WarnaRSIA.hijau;                     // masih banyak → hijau.
  }

  String _teksStatus(int tersedia) {
    if (tersedia == 0) return 'Penuh';
    if (tersedia <= 3) return 'Hampir Penuh';
    return 'Tersedia';
  }

  @override
  Widget build(BuildContext context) {
    // ===== DATA CONTOH (nanti dari API) =====
    final List<Map<String, dynamic>> kamar = [
      {'kelas': 'Kelas VIP', 'tersedia': 2, 'total': 6, 'harga': 'Rp 450.000 / malam'},
      {'kelas': 'Kelas 1', 'tersedia': 5, 'total': 20, 'harga': 'Rp 250.000 / malam'},
      {'kelas': 'Kelas 2', 'tersedia': 3, 'total': 24, 'harga': 'Rp 150.000 / malam'},
      {'kelas': 'Kelas 3', 'tersedia': 0, 'total': 30, 'harga': 'Rp 75.000 / malam'},
      {'kelas': 'ICU', 'tersedia': 4, 'total': 10, 'harga': 'Rp 800.000 / malam'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Ketersediaan Kamar')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: kamar.length,
        itemBuilder: (context, index) {
          final k = kamar[index];
          final tersedia = k['tersedia'] as int;
          final total = k['total'] as int;
          // value = isi bar progres dari 0.0 sampai 1.0.
          // total == 0 ? 0 : ... = hindari pembagian nol (jaga keamanan).
          final persentase = total == 0 ? 0.0 : tersedia / total;
          final warna = _warnaStatus(tersedia);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: WarnaRSIA.garis)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Baris 1: nama kelas + kapsul status ---
                Row(
                  children: [
                    // Lingkaran berisi ikon tempat tidur.
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: warna.withOpacity(0.12), shape: BoxShape.circle),
                      child: Icon(Icons.hotel, color: warna, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(k['kelas'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: WarnaRSIA.teksGelap)),
                          Text(k['harga'] as String, style: const TextStyle(fontSize: 11.5, color: WarnaRSIA.teksAbu)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: warna.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                      child: Text(_teksStatus(tersedia), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: warna)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // --- Bar progres ketersediaan ---
                // LinearProgressIndicator(value: 0..1) = garis progres horizontal.
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: persentase,
                    minHeight: 8, // ketebalan bar.
                    backgroundColor: WarnaRSIA.garis,
                    valueColor: AlwaysStoppedAnimation<Color>(warna),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tersedia $tersedia dari $total tempat tidur',
                  style: const TextStyle(fontSize: 12, color: WarnaRSIA.teksAbu),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}