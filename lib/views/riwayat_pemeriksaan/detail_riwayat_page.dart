// ============================================================
//  detail_riwayat_page.dart — DETAIL PEMERIKSAAN (BARU)
//
//  Dibuka dari halaman Riwayat Periksa saat pasien menekan salah satu
//  kartu kunjungan. Data header (poli, dokter, tanggal) langsung tampil
//  dari kartu yang ditap, lalu halaman memuat detail lengkapnya:
//
//  SINKRON DENGAN BACKEND:
//  Endpoint = GET /api/pasien/riwayat/detail?no_rawat=...
//  (PasienRiwayatController@detail)
//
//  Struktur respons dari server:
//  data = {
//    kunjungan : {...}        -> info reg_periksa (poli, dokter, dst);
//                                untuk Ranap juga ada nm_bangsal & kd_kamar
//                                terakhir (dari kamar_inap) untuk judul header
//    jenis     : "Ralan"|"Ranap"
//    pemeriksaan: [ {...}, ]  -> seluruh baris pemeriksaan_ralan (Ralan)
//                                atau pemeriksaan_ranap (Ranap). Bisa
//                                lebih dari 1 baris per kunjungan.
//    kamar     : [ {...}, ]   -> hanya Ranap: isi kamar_inap (bisa >1
//                                baris kalau pasien pindah kamar).
//                                Nama ruangan = kd_kamar (tabel kamar di
//                                SIMRS ini tidak punya kolom nm_kamar)
//    total_biaya_kamar: angka -> hanya Ranap
//  }
//
//  Tampilan per baris pemeriksaan (ExpansionTile, yang pertama terbuka):
//  - Kotak tanda vital (tensi, suhu, nadi, RR, SpO2, GCS, kesadaran,
//    tinggi, berat, lingkar perut [hanya Ralan]) — kotak kosong otomatis
//    disembunyikan.
//  - Paragraf: keluhan, hasil pemeriksaan, penilaian, RTL, instruksi,
//    evaluasi — paragraf kosong otomatis disembunyikan.
//  - Alergi ditampilkan dengan sorotan merah kalau ada isinya.
// ============================================================
import 'package:flutter/material.dart';
import '../../tema_rsia.dart';
import '../../services/api_service.dart';

class DetailRiwayatPage extends StatefulWidget {
  final String token;                   // dipakai otomatis oleh ApiService
  final Map<String, dynamic> kunjungan; // data kartu dari halaman list

  const DetailRiwayatPage({super.key, required this.token, required this.kunjungan});

  @override
  State<DetailRiwayatPage> createState() => _DetailRiwayatPageState();
}

class _DetailRiwayatPageState extends State<DetailRiwayatPage> {
  bool _memuat = true;
  String? _error;
  Map<String, dynamic> _detail = {};
  late String _noRawat;

  @override
  void initState() {
    super.initState();
    _noRawat = '${widget.kunjungan['no_rawat'] ?? ''}';
    _muatData();
  }

  // → GET /api/pasien/riwayat/detail?no_rawat=...
  // no_rawat di-encode karena mengandung karakter "/". Laravel otomatis
  // menerimanya sebagai parameter query "no_rawat".
  Future<void> _muatData() async {
    if (_noRawat.isEmpty) {
      setState(() { _error = 'No. rawat tidak tersedia pada data kunjungan.'; _memuat = false; });
      return;
    }
    setState(() { _memuat = true; _error = null; });
    try {
      final hasil = await ApiService.get('/riwayat/detail?no_rawat=${Uri.encodeComponent(_noRawat)}');
      if (!mounted) return;
      setState(() {
        _detail = (hasil['data'] as Map<String, dynamic>?) ?? {};
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _memuat = false; });
    }
  }

  // ============================================================
  // HELPER TAMPILAN
  // ============================================================

  // Teks aman: null / kosong -> '-'.
  String _txt(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? '-' : s;
  }

  static const _namaBulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                             'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

  // "2025-06-12" -> "12 Jun 2025" (tanpa paket intl).
  String _tgl(dynamic v) {
    final s = v?.toString().trim() ?? '';
    if (s.length < 10) return s.isEmpty ? '-' : s;
    final p = s.split('-');
    if (p.length < 3) return s;
    final idx = int.tryParse(p[1]);
    if (idx == null || idx < 1 || idx > 12) return s;
    return '${p[2]} ${_namaBulan[idx - 1]} ${p[0]}';
  }

  // "08:30:00" -> "08:30".
  String _jam(dynamic v) {
    final s = v?.toString() ?? '';
    return s.length >= 5 ? s.substring(0, 5) : (s.isEmpty ? '-' : s);
  }

  // Angka -> "Rp 1.500.000" (tanpa paket intl).
  String _rupiah(dynamic v) {
    final n = v is num ? v : num.tryParse('${v ?? ''}');
    if (n == null) return '-';
    final s = n.toStringAsFixed(0);
    final hasil = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      hasil.write(s[i]);
      final sisa = s.length - i;
      if (sisa > 1 && sisa % 3 == 1) hasil.write('.');
    }
    return 'Rp ${hasil.toString()}';
  }

  // "3.0" hari -> "3 hari", "3.5" tetap "3.5 hari".
  String _lamaHari(dynamic v) {
    final n = v is num ? v : num.tryParse('${v ?? ''}');
    if (n == null) return '-';
    final s = (n == n.roundToDouble()) ? n.toInt().toString() : n.toString();
    return '$s hari';
  }

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

  Color _warnaBayar(String s) =>
      s.toLowerCase() == 'belum bayar' ? WarnaRSIA.merah : WarnaRSIA.hijau;

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

  Color _warnaPulang(String s) {
    if (s == '-') return WarnaRSIA.teksAbu;
    if (['Sembuh', 'Sehat', 'Membaik', 'Isoman'].contains(s)) return WarnaRSIA.hijau;
    if (['Meninggal'].contains(s)) return WarnaRSIA.merah;
    return WarnaRSIA.biru;
  }

  Widget _barisData(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: WarnaRSIA.teksAbu)),
          ),
          Expanded(
            child: Text(nilai, style: const TextStyle(fontSize: 12.5, color: WarnaRSIA.teksGelap)),
          ),
        ],
      ),
    );
  }

  Widget _judulBagian(String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(teks, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: WarnaRSIA.teksGelap)),
    );
  }

  // ============================================================
  // KARTU RINGKASAN KUNJUNGAN (bagian atas halaman)
  // ============================================================

  Widget _kartuKunjungan(Map<String, dynamic> k, bool ranap) {
    // Rawat inap: judul = nama bangsal (bukan poli IGD) + baris kode kamar.
    final nmBangsal = _txt(k['nm_bangsal']);
    final kdKamar = _txt(k['kd_kamar']);
    final lokasi = (ranap && nmBangsal != '-') ? nmBangsal : _txt(k['nm_poli']);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WarnaRSIA.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lokasi,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: WarnaRSIA.teksGelap),
                ),
              ),
              _chip(ranap ? 'RAWAT INAP' : 'RAWAT JALAN', ranap ? Colors.deepOrange : WarnaRSIA.biru),
            ],
          ),
          const SizedBox(height: 10),
          _barisData('Dokter', _txt(k['nm_dokter'])),
          if (ranap && kdKamar != '-')
            _barisData('Kamar', kdKamar),
          _barisData('Tanggal', '${_tgl(k['tgl_registrasi'])}  •  ${_jam(k['jam_reg'])}'),
          _barisData('No. Rawat', _txt(k['no_rawat'])),
          _barisData('No. Reg', _txt(k['no_reg'])),
          _barisData('Penjamin', _txt(k['nm_pj'])),
          _barisData('Umur', _txt(k['umur'])),
          _barisData('Status', '${_txt(k['stts'])}  •  Daftar ${_txt(k['stts_daftar'])}'),
          _barisData('P. Jawab', '${_txt(k['p_jawab'])} (${_txt(k['hubunganpj'])})'),
          Row(
            children: [
              const Spacer(),
              _chip(_txt(k['status_bayar']), _warnaBayar(_txt(k['status_bayar']))),
              const SizedBox(width: 8),
              _chip(_txt(k['stts']), _warnaStts(_txt(k['stts']))),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KARTU KAMAR (hanya rawat inap)
  // ============================================================

  Widget _kartuKamar(Map<String, dynamic> km) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WarnaRSIA.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_txt(km['nm_bangsal'])} — ${_txt(km['kd_kamar'])}',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: WarnaRSIA.teksGelap),
                ),
              ),
              _chip(_txt(km['stts_pulang']), _warnaPulang(_txt(km['stts_pulang']))),
            ],
          ),
          const SizedBox(height: 8),
          if (_txt(km['kelas']) != '-')
            _barisData('Kelas', _txt(km['kelas'])),
          _barisData('Masuk', '${_tgl(km['tgl_masuk'])}  •  ${_jam(km['jam_masuk'])}'),
          _barisData('Keluar', '${_tgl(km['tgl_keluar'])}  •  ${_jam(km['jam_keluar'])}'),
          _barisData('Lama', _lamaHari(km['lama'])),
          _barisData('Tarif kamar', _rupiah(km['trf_kamar'])),
          _barisData('Biaya kamar', _rupiah(km['ttl_biaya'])),
          if (_txt(km['diagnosa_awal']) != '-')
            _barisData('Diag. awal', _txt(km['diagnosa_awal'])),
          if (_txt(km['diagnosa_akhir']) != '-')
            _barisData('Diag. akhir', _txt(km['diagnosa_akhir'])),
        ],
      ),
    );
  }

  Widget _barisTotalBiayaKamar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: WarnaRSIA.biru.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WarnaRSIA.biru.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Text('Total biaya kamar',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: WarnaRSIA.teksAbu)),
          const Spacer(),
          Text(_rupiah(_detail['total_biaya_kamar']),
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: WarnaRSIA.biru)),
        ],
      ),
    );
  }

  // ============================================================
  // KARTU PEMERIKSAAN (tiap baris pemeriksaan_ralan / _ranap)
  // ============================================================

  Widget _kartuPemeriksaan(int index, Map<String, dynamic> p) {
    final vital = (p['tanda_vital'] as Map<String, dynamic>?) ?? {};

    // Susun daftar tanda vital; yang kosong otomatis tidak muncul.
    final daftarVital = <Map<String, String>>[];
    void tambah(String label, dynamic v) {
      final s = _txt(v);
      if (s != '-') daftarVital.add({'label': label, 'nilai': s});
    }
    tambah('Tensi', vital['tensi']);
    tambah('Suhu', vital['suhu_tubuh']);
    tambah('Nadi', vital['nadi']);
    tambah('RR', vital['respirasi']);
    tambah('SpO2', vital['spo2']);
    tambah('GCS', vital['gcs']);
    tambah('Kesadaran', vital['kesadaran']);
    tambah('Tinggi', vital['tinggi']);
    tambah('Berat', vital['berat']);
    tambah('L. Perut', vital['lingkar_perut']); // hanya ada di Ralan

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WarnaRSIA.garis),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: index == 0,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(
            'Pemeriksaan ${index + 1} — ${_tgl(p['tgl_perawatan'])} ${_jam(p['jam_rawat'])}',
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: WarnaRSIA.teksGelap),
          ),
          subtitle: Text(
            'Pemeriksa: ${_txt(p['nama_petugas'])}',
            style: const TextStyle(fontSize: 12, color: WarnaRSIA.teksAbu),
          ),
          children: [
            if (daftarVital.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.1,
                ),
                itemCount: daftarVital.length,
                itemBuilder: (context, i) =>
                    _kotakVital(daftarVital[i]['label']!, daftarVital[i]['nilai']!),
              ),
              const SizedBox(height: 10),
            ],
            _blokTeks('Keluhan', p['keluhan']),
            _blokTeks('Hasil Pemeriksaan', p['pemeriksaan']),
            _blokTeks('Penilaian', p['penilaian']),
            _blokTeks('Rencana Tindak Lanjut (RTL)', p['rtl']),
            _blokTeks('Instruksi', p['instruksi']),
            _blokTeks('Evaluasi', p['evaluasi']),
            _blokTeksAlergi(p['alergi']),
          ],
        ),
      ),
    );
  }

  Widget _kotakVital(String label, String nilai) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: WarnaRSIA.biru.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WarnaRSIA.biru.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: WarnaRSIA.teksAbu)),
          const SizedBox(height: 2),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                nilai,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: WarnaRSIA.teksGelap),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blokTeks(String judul, dynamic isi) {
    final teks = _txt(isi);
    if (teks == '-') return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: WarnaRSIA.teksAbu)),
          const SizedBox(height: 4),
          Text(teks, style: const TextStyle(fontSize: 13, color: WarnaRSIA.teksGelap, height: 1.45)),
        ],
      ),
    );
  }

  // Blok alergi diberi sorotan merah karena penting bagi keamanan pasien.
  Widget _blokTeksAlergi(dynamic isi) {
    final teks = _txt(isi);
    if (teks == '-') return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: WarnaRSIA.merah.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WarnaRSIA.merah.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Alergi',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: WarnaRSIA.merah)),
          const SizedBox(height: 4),
          Text(teks,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: WarnaRSIA.teksGelap)),
        ],
      ),
    );
  }

  Widget _infoKosong(bool ranap) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: WarnaRSIA.garis),
      ),
      child: Column(
        children: [
          Icon(ranap ? Icons.local_hospital_outlined : Icons.assignment_outlined,
              size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            ranap
                ? 'Belum ada catatan pemeriksaan rawat inap untuk kunjungan ini.'
                : 'Belum ada catatan pemeriksaan rawat jalan untuk kunjungan ini.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD UTAMA
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // Header langsung pakai data kartu yang ditap, lalu diperbarui dari API.
    final kunjungan = (_detail['kunjungan'] as Map<String, dynamic>?) ?? widget.kunjungan;
    final jenis = '${_detail['jenis'] ?? kunjungan['status_lanjut'] ?? '-'}';
    final ranap = jenis == 'Ranap';
    final daftarPemeriksaan = (_detail['pemeriksaan'] as List?) ?? [];
    final daftarKamar = (_detail['kamar'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(ranap ? 'Detail Rawat Inap' : 'Detail Rawat Jalan')),
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
                  _kartuKunjungan(kunjungan, ranap),
                  const SizedBox(height: 14),

                  // ---- Data kamar: hanya kalau RAWAT INAP ----
                  if (ranap) ...[
                    _judulBagian('Data Kamar (${daftarKamar.length})'),
                    if (daftarKamar.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: WarnaRSIA.garis),
                        ),
                        child: const Text('Data kamar belum tersedia.',
                            style: TextStyle(fontSize: 12.5, color: Colors.grey)),
                      )
                    else ...[
                      for (final km in daftarKamar) _kartuKamar(km as Map<String, dynamic>),
                      _barisTotalBiayaKamar(),
                    ],
                    const SizedBox(height: 10),
                  ],

                  // ---- Catatan pemeriksaan ----
                  _judulBagian('Catatan Pemeriksaan (${daftarPemeriksaan.length})'),
                  if (daftarPemeriksaan.isEmpty)
                    _infoKosong(ranap)
                  else
                    for (var i = 0; i < daftarPemeriksaan.length; i++)
                      _kartuPemeriksaan(i, daftarPemeriksaan[i] as Map<String, dynamic>),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
