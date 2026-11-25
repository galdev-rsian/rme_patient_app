// ============================================================
//  riwayat_periksa_page.dart — Menu "Riwayat Periksa" — SUDAH
//  TERHUBUNG KE API (bukan data dummy lagi!).
//
//  SINKRON DENGAN BACKEND:
//  Endpoint = GET /api/pasien/kunjungan
//  (PasienPendaftaranController@riwayatKunjungan)
//  Server membaca tabel reg_periksa milik pasien yang login
//  (join poliklinik + dokter supaya dapat nama poli & nama dokter),
//  urut dari kunjungan TERBARU, maksimal 50 baris.
// ============================================================
import 'package:flutter/material.dart';
import '../../tema_rsia.dart';
import '../../services/api_service.dart';

class RiwayatPeriksaPage extends StatefulWidget {
  final String token; // token login — dipakai otomatis oleh ApiService.

  const RiwayatPeriksaPage({super.key, required this.token});

  @override
  State<RiwayatPeriksaPage> createState() => _RiwayatPeriksaPageState();
}

class _RiwayatPeriksaPageState extends State<RiwayatPeriksaPage> {
  bool _memuat = true;
  String? _error;
  List _kunjungan = [];

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() { _memuat = true; _error = null; });
    try {
      // → GET /api/pasien/kunjungan — data = daftar kunjungan
      final hasil = await ApiService.get('/kunjungan');
      if (!mounted) return;
      setState(() {
        _kunjungan = (hasil['data'] as List?) ?? [];
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _memuat = false; });
    }
  }

  // Chip kecil status pembayaran: Belum Bayar = merah, selain itu hijau.
  Color _warnaBayar(String s) => s.toLowerCase() == 'belum bayar' ? WarnaRSIA.merah : WarnaRSIA.hijau;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Periksa')),
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
          : _kunjungan.isEmpty
          ? const Center(child: Text('Belum ada riwayat kunjungan.', style: TextStyle(color: Colors.grey)))
          : RefreshIndicator( // tarik ke bawah untuk muat ulang — khas aplikasi modern.
        onRefresh: _muatData,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _kunjungan.length,
          itemBuilder: (context, index) {
            final k = _kunjungan[index] as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: WarnaRSIA.garis),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Baris 1: nama poli + chip status Baru/Lama.
                  Row(
                    children: [
                      Expanded(
                        child: Text('${k['nm_poli'] ?? '-'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: WarnaRSIA.teksGelap)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: WarnaRSIA.biru.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('${k['status_lanjut'] ?? '-'}',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: WarnaRSIA.biru)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Baris 2: dokter + tanggal kunjungan.
                  Text('Dokter: ${k['nm_dokter'] ?? '-'}', style: const TextStyle(fontSize: 12.5, color: WarnaRSIA.teksAbu)),
                  Text('Tgl: ${k['tgl_registrasi'] ?? '-'}  •  Jam: ${k['jam_reg'] ?? '-'}',
                      style: const TextStyle(fontSize: 12.5, color: WarnaRSIA.teksAbu)),
                  const SizedBox(height: 8),
                  // Baris 3: no. rawat + no. reg + chip pembayaran.
                  Row(
                    children: [
                      Expanded(
                        child: Text('No. Rawat ${k['no_rawat'] ?? '-'}  •  Reg ${k['no_reg'] ?? '-'}',
                            style: const TextStyle(fontSize: 11, color: WarnaRSIA.teksAbu, fontStyle: FontStyle.italic)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: _warnaBayar('${k['status_bayar'] ?? ''}').withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('${k['status_bayar'] ?? '-'}',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: _warnaBayar('${k['status_bayar'] ?? ''}'))),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}