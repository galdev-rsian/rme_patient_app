// ============================================================
//  notifikasi_page.dart — Modul "Notifikasi" — SUDAH TERHUBUNG
//  KE API (bukan data contoh lagi!).
//
//  SINKRON DENGAN BACKEND:
//  • Daftar    → GET  /api/pasien/notifikasi  (PasienNotifikasiController@index)
//  • Tandai    → POST /api/pasien/notifikasi/{id}/baca (tandaiBaca)
//  Jawaban daftar: { status, message, data: [...], belum_baca: 3 }
//  → 'belum_baca' dipakai dashboard untuk titik merah di ikon lonceng.
//  Tabel pasien_notifikasi dibuat lewat file migrasi-tabel-pasien.sql;
//  notifikasi bisa dikirim otomatis modul lain (contoh: pendaftaran
//  berhasil) atau diinput staf.
// ============================================================
import 'package:flutter/material.dart';
import '../../tema_rsia.dart';
import '../../services/api_service.dart';

class NotifikasiPage extends StatefulWidget {
  final String token;

  const NotifikasiPage({super.key, required this.token});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  bool _memuat = true;
  String? _error;
  List _notifikasi = [];
  int _belumBaca = 0; // angka dari key 'belum_baca' milik server.

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() { _memuat = true; _error = null; });
    try {
      // → GET /api/pasien/notifikasi
      final hasil = await ApiService.get('/notifikasi');
      if (!mounted) return;
      setState(() {
        _notifikasi = (hasil['data'] as List?) ?? [];
        _belumBaca = (hasil['belum_baca'] as num?)?.toInt() ?? 0;
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _memuat = false; });
    }
  }

  // ===== Ketuk satu notifikasi → tandai SUDAH DIBACA di server, lalu muat ulang =====
  Future<void> _tandaiBaca(Map item) async {
    final id = item['id'];
    if (item['is_baca'] == 1) return; // sudah dibaca → tidak perlu POST lagi.
    try {
      // → POST /api/pasien/notifikasi/{id}/baca
      // Server mengecek kepemilikan (WHERE no_rkm_medis = pasien login),
      // jadi tidak mungkin menandai notifikasi pasien lain.
      await ApiService.post('/notifikasi/$id/baca', {});
      await _muatData(); // refresh supaya titik "baru" hilang & angka berkurang.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: WarnaRSIA.merah),
      );
    }
  }

  // ===== Tombol "Tandai semua dibaca" → POST satu per satu untuk yang belum dibaca =====
  Future<void> _tandaiSemua() async {
    final yangBelum = _notifikasi.where((n) => (n as Map)['is_baca'] == 0);
    if (yangBelum.isEmpty) return;
    for (final n in yangBelum) {
      try {
        await ApiService.post('/notifikasi/${n['id']}/baca', {});
      } catch (_) {/* lewati yang gagal, lanjut sisanya */}
    }
    await _muatData();
  }

  // Pilih ikon sesuai kolom 'tipe' dari server: lab / resep / tagihan / jadwal / info.
  IconData _ikonTipe(String tipe) {
    switch (tipe.toLowerCase()) {
      case 'lab':
        return Icons.science;
      case 'resep':
        return Icons.medication;
      case 'tagihan':
        return Icons.receipt_long;
      case 'jadwal':
        return Icons.event_available;
      default:
        return Icons.campaign; // 'info' / lainnya
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
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
          : Column(
        children: [
          // ===== Header: jumlah belum dibaca + tombol tandai semua =====
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                // Chip jumlah belum dibaca (dari server).
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _belumBaca > 0 ? WarnaRSIA.merah.withOpacity(0.1) : WarnaRSIA.latar,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _belumBaca > 0 ? WarnaRSIA.merah.withOpacity(0.3) : WarnaRSIA.garis),
                  ),
                  child: Text(
                    _belumBaca > 0 ? '$_belumBaca belum dibaca' : 'Semua sudah dibaca',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _belumBaca > 0 ? WarnaRSIA.merah : WarnaRSIA.teksAbu),
                  ),
                ),
                const Spacer(), // mendorong tombol ke kanan.
                TextButton(
                  onPressed: _belumBaca > 0 ? _tandaiSemua : null, // nonaktif kalau tidak ada yang belum.
                  child: const Text('Tandai semua dibaca', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          // ===== Daftar notifikasi (dari server) =====
          Expanded(
            child: _notifikasi.isEmpty
                ? const Center(child: Text('Belum ada notifikasi.', style: TextStyle(color: Colors.grey)))
                : RefreshIndicator(
              onRefresh: _muatData,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _notifikasi.length,
                itemBuilder: (context, index) {
                  final n = _notifikasi[index] as Map<String, dynamic>;
                  final baru = n['is_baca'] == 0; // 0 = belum dibaca
                  return InkWell(
                    onTap: () => _tandaiBaca(n), // ketuk = tandai dibaca.
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: baru ? WarnaRSIA.hijau.withOpacity(0.06) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: baru ? WarnaRSIA.hijau.withOpacity(0.25) : WarnaRSIA.garis),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ikon mengikuti 'tipe' dari server.
                          Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(color: WarnaRSIA.biru.withOpacity(0.1), shape: BoxShape.circle),
                            child: Icon(_ikonTipe('${n['tipe'] ?? 'info'}'), color: WarnaRSIA.biru, size: 19),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text('${n['judul'] ?? '-'}',
                                          style: TextStyle(fontWeight: baru ? FontWeight.bold : FontWeight.w600, fontSize: 13.5, color: WarnaRSIA.teksGelap)),
                                    ),
                                    // created_at dari server, tampil kecil.
                                    Text('${n['created_at'] ?? ''}'.split(' ').first,
                                        style: const TextStyle(fontSize: 10.5, color: WarnaRSIA.teksAbu)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('${n['pesan'] ?? ''}', style: const TextStyle(fontSize: 12.5, color: WarnaRSIA.teksAbu, height: 1.45)),
                              ],
                            ),
                          ),
                          // Titik kecil penanda "belum dibaca".
                          if (baru)
                            const Padding(
                              padding: EdgeInsets.only(left: 8, top: 4),
                              child: CircleAvatar(radius: 4, backgroundColor: WarnaRSIA.hijau),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}