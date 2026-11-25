// ============================================================
//  jadwal_kontrol_page.dart — Menu "Jadwal Kontrol" — SUDAH
//  TERHUBUNG KE API.
//
//  SINKRON DENGAN BACKEND:
//  Endpoint = GET /api/pasien/kunjungan (sama dengan Riwayat
//  Periksa — PasienPendaftaranController@riwayatKunjungan).
//  Bedanya hanya di SISI APLIKASI: daftar kunjungan yang diambil
//  DIFILTER, hanya menampilkan kunjungan yang tanggalnya
//  >= hari ini (= kunjungan yang akan datang / jadwal kontrol).
//  Ini contoh bagus: satu endpoint backend bisa melayani dua menu
//  berbeda tanpa perlu route baru.
// ============================================================
import 'package:flutter/material.dart';
import '../../tema_rsia.dart';
import '../../services/api_service.dart';

class JadwalKontrolPage extends StatefulWidget {
  final String token;

  const JadwalKontrolPage({super.key, required this.token});

  @override
  State<JadwalKontrolPage> createState() => _JadwalKontrolPageState();
}

class _JadwalKontrolPageState extends State<JadwalKontrolPage> {
  bool _memuat = true;
  String? _error;
  List _jadwalAkanDatang = [];

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() { _memuat = true; _error = null; });
    try {
      final hasil = await ApiService.get('/kunjungan'); // → GET /api/pasien/kunjungan
      if (!mounted) return;
      final semua = (hasil['data'] as List?) ?? [];
      // Tanggal hari ini (tanpa jam) sebagai batas filter.
      final hariIni = DateTime.now();
      final batas = DateTime(hariIni.year, hariIni.month, hariIni.day);
      // DateTime.tryParse = ubah "2026-01-15" menjadi objek DateTime;
      // mengembalikan null kalau formatnya tidak dikenali → item dilewati.
      final filtered = semua.where((item) {
        final tgl = DateTime.tryParse('${item['tgl_registrasi'] ?? ''}');
        if (tgl == null) return false;
        // Bandingkan TANGGAL saja (tanpa jam): kunjungan hari ini & ke depan.
        final tglMurni = DateTime(tgl.year, tgl.month, tgl.day);
        return !tglMurni.isBefore(batas);
      }).toList();
      setState(() { _jadwalAkanDatang = filtered; _memuat = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _memuat = false; });
    }
  }

  // Nama hari dalam Bahasa Indonesia untuk tampilan tanggal.
  static const _namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  static const _namaBulan = ['', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

  String _formatTanggal(String? iso) {
    final t = DateTime.tryParse(iso ?? '');
    if (t == null) return iso ?? '-';
    return '${_namaHari[t.weekday - 1]}, ${t.day} ${_namaBulan[t.month]} ${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal Kontrol')),
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
          : _jadwalAkanDatang.isEmpty
      // Kosong BUKAN error — pasien memang belum punya jadwal ke depan.
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.event_busy, color: WarnaRSIA.teksAbu, size: 44),
            const SizedBox(height: 12),
            const Text('Belum ada jadwal kontrol mendatang.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('Jika dokter meminta Anda kontrol kembali, daftarkan lewat menu "Pendaftaran Online".',
                textAlign: TextAlign.center,
                style: TextStyle(color: WarnaRSIA.teksAbu, fontSize: 12.5)),
          ]),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _jadwalAkanDatang.length,
        itemBuilder: (context, index) {
          final k = _jadwalAkanDatang[index] as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: WarnaRSIA.garis),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(
              children: [
                // Ikon kalender dalam lingkaran hijau muda.
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(color: WarnaRSIA.hijau.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.calendar_month, color: WarnaRSIA.hijau, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${k['nm_poli'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: WarnaRSIA.teksGelap)),
                      const SizedBox(height: 3),
                      Text(_formatTanggal('${k['tgl_registrasi'] ?? ''}'),
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: WarnaRSIA.hijauTua)),
                      Text('Jam daftar: ${k['jam_reg'] ?? '-'}  •  Dokter: ${k['nm_dokter'] ?? '-'}',
                          style: const TextStyle(fontSize: 12, color: WarnaRSIA.teksAbu)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}