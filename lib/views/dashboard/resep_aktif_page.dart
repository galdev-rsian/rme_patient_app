// ============================================================
//  resep_aktif_page.dart — Menu "Resep Obat Aktif" — SUDAH
//  TERHUBUNG KE API.
//
//  SINKRON DENGAN BACKEND:
//  Endpoint = GET /api/pasien/resep (PasienResepController@index).
//  Jawaban 'data' berbentuk NESTED (bertingkat) — satu resep
//  berisi daftar obatnya:
//  [ { "no_resep": "...", "tgl_perawatan": "...", "nm_dokter": "...",
//      "status": "...",
//      "obat": [ {"nama_brng": "...", "jml": 10, "aturan_pakai": "..."} ] } ]
//  Karena itu di sini ada ListView (resep) DI DALAM kartu lagi
//  (obat) — pola umum saat API mengirim data bertingkat.
// ============================================================
import 'package:flutter/material.dart';
import '../../tema_rsia.dart';
import '../../services/api_service.dart';

class ResepAktifPage extends StatefulWidget {
  final String token;

  const ResepAktifPage({super.key, required this.token});

  @override
  State<ResepAktifPage> createState() => _ResepAktifPageState();
}

class _ResepAktifPageState extends State<ResepAktifPage> {
  bool _memuat = true;
  String? _error;
  List _reseps = [];

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() { _memuat = true; _error = null; });
    try {
      // → GET /api/pasien/resep — server join resep_obat + resep_dokter + databarang
      final hasil = await ApiService.get('/resep');
      if (!mounted) return;
      setState(() { _reseps = (hasil['data'] as List?) ?? []; _memuat = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _memuat = false; });
    }
  }

  // Chip warna status resep: 'selesai' hijau, selain itu kuning.
  Color _warnaStatus(String s) => s.toLowerCase() == 'selesai' ? WarnaRSIA.hijau : Colors.orange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resep Obat')),
      body: _memuat
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: WarnaRSIA.teksAbu, fontSize: 13)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _muatData, child: const Text('Coba Lagi')),
        ]),
      )
          : _reseps.isEmpty
          ? const Center(child: Text('Belum ada resep obat.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reseps.length,
        itemBuilder: (context, index) {
          final r = _reseps[index] as Map<String, dynamic>;
          final obatList = (r['obat'] as List?) ?? []; // daftar obat di dalam resep ini
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: WarnaRSIA.garis),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== KEPALA RESEP =====
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(color: WarnaRSIA.biru.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.medication, color: WarnaRSIA.biru, size: 21),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Resep ${r['no_resep'] ?? '-'}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: WarnaRSIA.teksGelap)),
                            Text('${r['tgl_perawatan'] ?? '-'} ${r['jam'] ?? ''}  •  ${r['nm_dokter'] ?? '-'}',
                                style: const TextStyle(fontSize: 11.5, color: WarnaRSIA.teksAbu)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(color: _warnaStatus('${r['status'] ?? ''}').withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                        child: Text('${r['status'] ?? '-'}', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: _warnaStatus('${r['status'] ?? ''}'))),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // ===== RINCIAN OBAT (dari key "obat") =====
                if (obatList.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Rincian obat belum tersedia.', style: TextStyle(color: WarnaRSIA.teksAbu, fontSize: 12.5)),
                  )
                else
                  ...obatList.map((o) {
                    final obat = o as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right, size: 18, color: WarnaRSIA.hijau),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // nama_brng = nama obat dari tabel databarang
                                Text('${obat['nama_brng'] ?? '-'}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: WarnaRSIA.teksGelap)),
                                // aturan_pakai contoh: "3 x 1 tablet sesudah makan"
                                Text('Aturan: ${obat['aturan_pakai'] ?? '-'}', style: const TextStyle(fontSize: 11.5, color: WarnaRSIA.teksAbu)),
                              ],
                            ),
                          ),
                          // jml = jumlah obat yang diresepkan
                          Text('x${obat['jml'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: WarnaRSIA.hijauTua)),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 14),
              ],
            ),
          );
        },
      ),
    );
  }
}