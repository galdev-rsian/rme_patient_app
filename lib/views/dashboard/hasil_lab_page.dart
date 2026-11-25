// ============================================================
//  hasil_lab_page.dart — Menu "Hasil Laboratorium" — SUDAH
//  TERHUBUNG KE API (bukan placeholder lagi!).
//
//  SINKRON DENGAN BACKEND:
//  • Daftar  → GET /api/pasien/lab              (PasienLabController@index)
//  • Detail  → GET /api/pasien/lab/{no_order}   (PasienLabController@detail)
//  Format jawaban selalu: {"status": true, "message": "...", "data": ...}
//  Keamanan: server HANYA mengirim lab milik pasien yang login —
//  identitas diambil dari token (middleware pasien.token), bukan
//  dikirim dari aplikasi. Aplikasi tidak pernah mengirim no. RM.
// ============================================================
import 'package:flutter/material.dart';
import '../../tema_rsia.dart';
import '../../services/api_service.dart';

class HasilLabPage extends StatefulWidget {
  final String token; // token login (otomatis dipakai ApiService dari storage).

  const HasilLabPage({super.key, required this.token});

  @override
  State<HasilLabPage> createState() => _HasilLabPageState();
}

class _HasilLabPageState extends State<HasilLabPage> {
  bool _memuat = true;   // true saat menunggu jawaban server → tampil spinner.
  String? _error;        // pesan error (null = tidak ada error).
  List _daftarLab = [];  // hasil 'data' dari server: daftar permintaan lab.

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  // ===== Ambil DAFTAR lab dari server =====
  Future<void> _muatData() async {
    setState(() { _memuat = true; _error = null; });
    try {
      final hasil = await ApiService.get('/lab'); // → GET /api/pasien/lab
      if (!mounted) return;
      setState(() {
        _daftarLab = (hasil['data'] as List?) ?? []; // data = array of object
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _memuat = false; });
    }
  }

  // ===== Ambil DETAIL satu order lab → tampilkan di lembar bawah (bottom sheet) =====
  Future<void> _bukaDetail(Map order) async {
    final noOrder = order['no_order'].toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mengambil detail $noOrder...'), duration: const Duration(seconds: 1)),
    );
    try {
      // → GET /api/pasien/lab/{no_order}; jawaban data = { header: {...}, hasil: [...] }
      final hasil = await ApiService.get('/lab/$noOrder');
      if (!mounted) return;
      final data = hasil['data'] as Map<String, dynamic>;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true, // sheet boleh tinggi (hampir 1 layar).
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75, // tinggi awal 75% layar.
          builder: (context, scrollCtrl) => ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(18),
            children: [
              Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: WarnaRSIA.garis, borderRadius: BorderRadius.circular(999)))),
              const SizedBox(height: 14),
              Text('${data['header']['nm_perawatan'] ?? ''}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: WarnaRSIA.teksGelap)),
              const SizedBox(height: 4),
              Text('No. Order: ${data['header']['no_order']}  •  ${data['header']['tgl_permintaan']} ${data['header']['jam_permintaan']}',
                  style: const TextStyle(fontSize: 12, color: WarnaRSIA.teksAbu)),
              const Divider(height: 24),
              // Kepala tabel hasil: nama pemeriksaan | nilai | nilai rujukan
              const Row(children: [
                Expanded(flex: 4, child: Text('Pemeriksaan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                Expanded(flex: 2, child: Text('Hasil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                Expanded(flex: 3, child: Text('Nilai Rujukan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
              ]),
              const Divider(),
              // data['hasil'] = daftar baris hasil per parameter (Hb, Leukosit, ...)
              ...(data['hasil'] as List? ?? []).map((baris) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: Text('${baris['Pemeriksaan'] ?? '-'}', style: const TextStyle(fontSize: 12.5))),
                    Expanded(flex: 2, child: Text('${baris['nilai'] ?? '-'}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: WarnaRSIA.hijauTua))),
                    Expanded(flex: 3, child: Text('${baris['nilai_ref'] ?? '-'}', style: const TextStyle(fontSize: 12, color: WarnaRSIA.teksAbu))),
                  ],
                ),
              )),
              if ((data['hasil'] as List? ?? []).isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Hasil belum tersedia — pemeriksaan masih diproses di laboratorium.',
                      style: TextStyle(color: WarnaRSIA.teksAbu, fontSize: 12.5)),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: WarnaRSIA.merah),
      );
    }
  }

  // Warna chip status lab: Permintaan = kuning, Proses = biru, Selesai = hijau.
  Color _warnaStatus(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return WarnaRSIA.hijau;
      case 'proses':
        return WarnaRSIA.biru;
      default:
        return Colors.orange; // 'Permintaan' / lainnya
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Laboratorium')),
      body: _memuat
      // Saat menunggu server → lingkaran berputar di tengah layar.
          ? const Center(child: CircularProgressIndicator())
          : _error != null
      // Gagal koneksi → pesan + tombol coba lagi.
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off, color: WarnaRSIA.teksAbu, size: 42),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: WarnaRSIA.teksAbu, fontSize: 13)),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: _muatData, child: const Text('Coba Lagi')),
          ]),
        ),
      )
          : _daftarLab.isEmpty
      // Server sukses tapi datanya kosong (pasien belum pernah lab).
          ? const Center(child: Text('Belum ada data laboratorium.', style: TextStyle(color: Colors.grey)))
      // Data ada → gambar daftar kartu.
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _daftarLab.length,
        itemBuilder: (context, index) {
          final item = _daftarLab[index] as Map<String, dynamic>;
          final status = '${item['status'] ?? '-'}';
          return InkWell(
            onTap: () => _bukaDetail(item), // ketuk → buka detail hasilnya.
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: WarnaRSIA.garis),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: WarnaRSIA.hijau.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.science, color: WarnaRSIA.hijau, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item['nm_perawatan'] ?? '-'}', // nama jenis pemeriksaan
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: WarnaRSIA.teksGelap)),
                        const SizedBox(height: 3),
                        Text('No. ${item['no_order']}  •  ${item['tgl_permintaan']} ${item['jam_permintaan']}',
                            style: const TextStyle(fontSize: 11.5, color: WarnaRSIA.teksAbu)),
                        if (item['nm_dokter'] != null)
                          Text('Dokter: ${item['nm_dokter']}', style: const TextStyle(fontSize: 11.5, color: WarnaRSIA.teksAbu)),
                      ],
                    ),
                  ),
                  // Chip status di kanan.
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _warnaStatus(status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(status, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: _warnaStatus(status))),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}