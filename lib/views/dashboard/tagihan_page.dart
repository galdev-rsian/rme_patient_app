// ============================================================
//  tagihan_page.dart — Menu "Tagihan & Pembayaran" — SUDAH
//  TERHUBUNG KE API.
//
//  SINKRON DENGAN BACKEND:
//  Endpoint = GET /api/pasien/tagihan (PasienTagihanController@index).
//  Jawaban 'data' per kunjungan:
//  [ { "no_rawat": "...", "tgl_registrasi": "...", "nm_poli": "...",
//      "status_bayar": "Belum Bayar",
//      "rincian": [ {"uraian": "Pendaftaran", "jumlah": 30000}, ... ],
//      "total": 120000 } ]
//  CATATAN: di SIMRS biaya menyebar di beberapa tabel — nilai rincian
//  bisa diarahkan ke tabel billing RS Anda di PasienTagihanController.
// ============================================================
import 'package:flutter/material.dart';
import '../../tema_rsia.dart';
import '../../services/api_service.dart';

class TagihanPage extends StatefulWidget {
  final String token;

  const TagihanPage({super.key, required this.token});

  @override
  State<TagihanPage> createState() => _TagihanPageState();
}

class _TagihanPageState extends State<TagihanPage> {
  bool _memuat = true;
  String? _error;
  List _tagihan = [];

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() { _memuat = true; _error = null; });
    try {
      // → GET /api/pasien/tagihan
      final hasil = await ApiService.get('/tagihan');
      if (!mounted) return;
      setState(() { _tagihan = (hasil['data'] as List?) ?? []; _memuat = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _memuat = false; });
    }
  }

  // ===== Helper: angka → format Rupiah =====
  // 120000 → "Rp 120.000". toLocaleString dengan locale 'id_ID' menambah
  // titik ribuan otomatis. Hex \u00A0 = spasi yang tidak bisa terpotong.
  String _rupiah(dynamic angka) {
    final n = (num.tryParse('${angka ?? 0}') ?? 0);
    final teks = n.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
    return 'Rp\u00A0$teks';
  }

  // Chip status pembayaran.
  Color _warnaBayar(String s) => s.toLowerCase() == 'belum bayar' ? WarnaRSIA.merah : WarnaRSIA.hijau;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tagihan & Pembayaran')),
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
          : _tagihan.isEmpty
          ? const Center(child: Text('Tidak ada tagihan yang perlu dibayar.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tagihan.length,
        itemBuilder: (context, index) {
          final t = _tagihan[index] as Map<String, dynamic>;
          final rincian = (t['rincian'] as List?) ?? []; // daftar komponen biaya
          final statusBayar = '${t['status_bayar'] ?? '-'}';
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: WarnaRSIA.garis),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== Kepala: poli + tanggal + chip status =====
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${t['nm_poli'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: WarnaRSIA.teksGelap)),
                          Text('Kunjungan ${t['tgl_registrasi'] ?? '-'}  •  ${t['no_rawat'] ?? '-'}',
                              style: const TextStyle(fontSize: 11.5, color: WarnaRSIA.teksAbu)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: _warnaBayar(statusBayar).withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                      child: Text(statusBayar, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: _warnaBayar(statusBayar))),
                    ),
                  ],
                ),
                const Divider(height: 22),
                // ===== Rincian komponen biaya =====
                // Hanya komponen berjumlah > 0 yang dikirim server.
                ...rincian.map((r) {
                  final item = r as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item['uraian'] ?? '-'}', style: const TextStyle(fontSize: 13, color: WarnaRSIA.teksAbu)),
                        Text(_rupiah(item['jumlah']), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: WarnaRSIA.teksGelap)),
                      ],
                    ),
                  );
                }),
                if (rincian.isEmpty)
                  const Text('Belum ada komponen biaya tercatat.', style: TextStyle(fontSize: 12.5, color: WarnaRSIA.teksAbu)),
                const Divider(height: 22),
                // ===== TOTAL =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: WarnaRSIA.teksGelap)),
                    // 'total' dihitung server (penjumlahan semua rincian).
                    Text(_rupiah(t['total']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: WarnaRSIA.hijauTua)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}