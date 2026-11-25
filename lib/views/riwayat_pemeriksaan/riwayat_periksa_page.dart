// ============================================================
//  riwayat_periksa_page.dart — Menu "Riwayat Periksa" (v2)
//
//  SINKRON DENGAN BACKEND:
//  Endpoint = GET /api/pasien/riwayat (PasienRiwayatController@daftar)
//  Server mengambil SEMUA kunjungan pasien yang login dari tabel
//  reg_periksa — RAWAT JALAN dan RAWAT INAP sekaligus (kolom
//  status_lanjut = 'Ralan' / 'Ranap'), join poliklinik + dokter +
//  penjab, urut dari kunjungan TERBARU, maksimal 200 baris.
//
//  Untuk RAWAT INAP: judul kartu memakai nama BANGSAL (kamar_inap
//  terakhir -> kamar -> bangsal), bukan nama poli IGD tempat pasien
//  pertama masuk; kode kamar tampil di baris terpisah.
//
//  FITUR HALAMAN INI:
//  - Kotak ringkasan: Total / Rawat Jalan / Rawat Inap.
//  - Filter chip: Semua / Rawat Jalan / Rawat Inap (difilter DI SISI
//    aplikasi, jadi tanpa request tambahan ke server).
//  - Ketuk kartu kunjungan -> buka DetailRiwayatPage yang memuat
//    seluruh catatan pemeriksaan (GET /api/pasien/riwayat/detail).
//  - Tarik ke bawah (RefreshIndicator) untuk memuat ulang.
//
//  Letakkan file ini di folder yang sama dengan versi lama
//  (satu folder dengan detail_riwayat_page.dart).
// ============================================================
import 'package:flutter/material.dart';
import '../../tema_rsia.dart';
import '../../services/api_service.dart';
import 'detail_riwayat_page.dart';

class RiwayatPeriksaPage extends StatefulWidget {
  final String token; // token login — dipakai otomatis oleh ApiService.

  const RiwayatPeriksaPage({super.key, required this.token});

  @override
  State<RiwayatPeriksaPage> createState() => _RiwayatPeriksaPageState();
}

class _RiwayatPeriksaPageState extends State<RiwayatPeriksaPage> {
  bool _memuat = true;
  String? _error;
  List _kunjungan = [];    // semua kunjungan dari server (Ralan + Ranap)
  Map _ringkasan = {};     // { total, ralan, ranap, ditampilkan }
  String _filter = 'Semua'; // Semua | Ralan | Ranap

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  // → GET /api/pasien/riwayat — data = daftar kunjungan, ringkasan = jumlah.
  Future<void> _muatData() async {
    setState(() { _memuat = true; _error = null; });
    try {
      final hasil = await ApiService.get('/riwayat');
      if (!mounted) return;
      setState(() {
        _kunjungan = (hasil['data'] as List?) ?? [];
        _ringkasan = (hasil['ringkasan'] as Map?) ?? {};
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _memuat = false; });
    }
  }

  // Daftar yang sudah tersaring sesuai pilihan chip (client-side).
  List get _daftarTampil {
    if (_filter == 'Semua') return _kunjungan;
    return _kunjungan.where((k) => k['status_lanjut'] == _filter).toList();
  }

  // ============================================================
  // WARNA CHIP
  // ============================================================

  // Chip pembayaran: Belum Bayar = merah, selain itu hijau.
  Color _warnaBayar(String s) =>
      s.toLowerCase() == 'belum bayar' ? WarnaRSIA.merah : WarnaRSIA.hijau;

  // Chip status kunjungan dari reg_periksa.stts.
  Color _warnaStts(String s) {
    switch (s) {
      case 'Sudah':
      case 'Dipanggil':
        return WarnaRSIA.hijau;
      case 'Belum':
        return Colors.orange;
      case 'Dirawat':
        return WarnaRSIA.biru;
      case 'Batal':
      case 'Dirujuk':
      case 'Meninggal':
      case 'Pulang Paksa':
        return WarnaRSIA.merah;
      default:
        return WarnaRSIA.teksAbu;
    }
  }

  // ============================================================
  // WIDGET KECIL
  // ============================================================

  Widget _chip(String teks, Color warna) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: warna.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        teks,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: warna),
      ),
    );
  }

  Widget _kotakRingkasan(String label, String nilai, Color warna) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: warna.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: warna.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Text(nilai, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: warna)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: WarnaRSIA.teksAbu)),
          ],
        ),
      ),
    );
  }

  Widget _pilihanFilter(String nilai, String label) {
    final terpilih = _filter == nilai;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filter = nilai),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: terpilih ? WarnaRSIA.biru : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: terpilih ? WarnaRSIA.biru : WarnaRSIA.garis),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: terpilih ? FontWeight.bold : FontWeight.normal,
              color: terpilih ? Colors.white : WarnaRSIA.teksAbu,
            ),
          ),
        ),
      ),
    );
  }

  Widget _kartuKunjungan(Map<String, dynamic> k) {
    final jenis = '${k['status_lanjut'] ?? '-'}';
    final ranap = jenis == 'Ranap';
    // Rawat inap: tampilkan nama bangsal (bukan poli IGD) + kode kamar.
    final nmBangsal = '${k['nm_bangsal'] ?? ''}'.trim();
    final kdKamar = '${k['kd_kamar'] ?? ''}'.trim();
    final lokasi = (ranap && nmBangsal.isNotEmpty) ? nmBangsal : '${k['nm_poli'] ?? '-'}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WarnaRSIA.garis),
      ),
      child: Material(
        color: Colors.transparent, // biar efek tekan (ripple) terlihat
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          // Ketuk kartu -> buka detail pemeriksaan lengkap.
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailRiwayatPage(token: widget.token, kunjungan: k),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris 1: nama poli + chip jenis (Rawat Jalan / Rawat Inap).
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lokasi,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14, color: WarnaRSIA.teksGelap),
                      ),
                    ),
                    _chip(ranap ? 'RAWAT INAP' : 'RAWAT JALAN', ranap ? Colors.deepOrange : WarnaRSIA.biru),
                  ],
                ),
                const SizedBox(height: 6),
                // Baris 2: dokter + tanggal + jam + status kunjungan.
                Text(
                  'Dokter: ${k['nm_dokter'] ?? '-'}',
                  style: const TextStyle(fontSize: 12.5, color: WarnaRSIA.teksAbu),
                ),
                if (ranap && kdKamar.isNotEmpty)
                  Text(
                    'Kamar: $kdKamar',
                    style: const TextStyle(fontSize: 12.5, color: WarnaRSIA.teksAbu),
                  ),
                Text(
                  'Tgl: ${k['tgl_registrasi'] ?? '-'}  •  Jam: ${k['jam_reg'] ?? '-'}  •  Status: ${k['stts'] ?? '-'}',
                  style: const TextStyle(fontSize: 12.5, color: WarnaRSIA.teksAbu),
                ),
                const SizedBox(height: 8),
                // Baris 3: no. rawat + no. reg + chip pembayaran.
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'No. Rawat ${k['no_rawat'] ?? '-'}  •  Reg ${k['no_reg'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 11, color: WarnaRSIA.teksAbu, fontStyle: FontStyle.italic),
                      ),
                    ),
                    _chip('${k['status_bayar'] ?? '-'}', _warnaBayar('${k['status_bayar'] ?? ''}')),
                  ],
                ),
                // Baris 4 (opsional): badge kalau catatan pemeriksaan belum ada.
                if (k['ada_pemeriksaan'] == false)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Catatan pemeriksaan belum tersedia.',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.orange.shade700),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD UTAMA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final daftar = _daftarTampil;
    final totalSemua = '${_ringkasan['total'] ?? _kunjungan.length}';
    final ditampilkan = (_ringkasan['ditampilkan'] ?? _kunjungan.length) as num;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Periksa')),
      body: _memuat
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(_error!, textAlign: TextAlign.center,
                        style: const TextStyle(color: WarnaRSIA.teksAbu, fontSize: 13)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _muatData, child: const Text('Coba Lagi')),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _muatData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Ringkasan jumlah kunjungan per jenis.
                  Row(
                    children: [
                      _kotakRingkasan('Total', totalSemua, WarnaRSIA.biru),
                      const SizedBox(width: 10),
                      _kotakRingkasan('Rawat Jalan', '${_ringkasan['ralan'] ?? 0}', WarnaRSIA.hijau),
                      const SizedBox(width: 10),
                      _kotakRingkasan('Rawat Inap', '${_ringkasan['ranap'] ?? 0}', Colors.deepOrange),
                    ],
                  ),
                  // Kalau data terpotong limit 200, beri tahu pasien.
                  if (ditampilkan > 0 && ditampilkan < (num.tryParse(totalSemua) ?? 0))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Menampilkan $ditampilkan kunjungan terbaru dari total $totalSemua.',
                        style: const TextStyle(fontSize: 11.5, color: WarnaRSIA.teksAbu, fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 14),
                  // Chip filter jenis kunjungan.
                  Row(
                    children: [
                      _pilihanFilter('Semua', 'Semua'),
                      const SizedBox(width: 8),
                      _pilihanFilter('Ralan', 'Rawat Jalan'),
                      const SizedBox(width: 8),
                      _pilihanFilter('Ranap', 'Rawat Inap'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Daftar kartu kunjungan (atau pesan kosong).
                  if (daftar.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      alignment: Alignment.center,
                      child: Text(
                        _filter == 'Semua'
                            ? 'Belum ada riwayat kunjungan.'
                            : 'Belum ada kunjungan ${_filter == 'Ralan' ? 'rawat jalan' : 'rawat inap'}.',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    )
                  else
                    for (final k in daftar) _kartuKunjungan(k as Map<String, dynamic>),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }
}
