// ============================================================
//  edukasi_page.dart — Modul "Artikel Kesehatan" — SUDAH
//  TERHUBUNG KE API.
//
//  SINKRON DENGAN BACKEND:
//  • Daftar  → GET /api/pasien/edukasi            (PasienEdukasiController@index)
//  • Detail  → GET /api/pasien/edukasi/{id}       (PasienEdukasiController@detail)
//  Daftar HANYA mengirim judul + kategori + tanggal (hemat kuota data
//  pasien); isi lengkap artikel baru diambil saat artikel diketuk.
//  Isi artikel diinput staf RS ke tabel pasien_edukasi lewat aplikasi
//  web RME (tabel dibuat lewat migrasi-tabel-pasien.sql).
// ============================================================
import 'package:flutter/material.dart';
import '../../tema_rsia.dart';
import '../../services/api_service.dart';

class EdukasiPage extends StatefulWidget {
  final String token;

  const EdukasiPage({super.key, required this.token});

  @override
  State<EdukasiPage> createState() => _EdukasiPageState();
}

class _EdukasiPageState extends State<EdukasiPage> {
  bool _memuat = true;
  String? _error;
  List _artikel = [];

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() { _memuat = true; _error = null; });
    try {
      // → GET /api/pasien/edukasi (bisa ditambah ?kategori=hipertensi —
      //   backend menyaring berdasarkan kolom kategori).
      final hasil = await ApiService.get('/edukasi');
      if (!mounted) return;
      setState(() { _artikel = (hasil['data'] as List?) ?? []; _memuat = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _memuat = false; });
    }
  }

  // ===== Ketuk artikel → ambil isi lengkapnya → tampilkan di bottom sheet =====
  Future<void> _bukaArtikel(Map artikel) async {
    final id = artikel['id'];
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Memuat artikel...'), duration: Duration(seconds: 1)),
    );
    try {
      // → GET /api/pasien/edukasi/{id} — data = 1 objek lengkap (judul, kategori, isi)
      final hasil = await ApiService.get('/edukasi/$id');
      if (!mounted) return;
      final data = hasil['data'] as Map<String, dynamic>;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          builder: (context, scrollCtrl) => ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(20),
            children: [
              Center(child: Container(width: 44, height: 4, decoration: BoxDecoration(color: WarnaRSIA.garis, borderRadius: BorderRadius.circular(999)))),
              const SizedBox(height: 16),
              // Chip kategori + judul + tanggal.
              Wrap(spacing: 8, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: WarnaRSIA.hijau.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                  child: Text('${data['kategori'] ?? 'Umum'}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: WarnaRSIA.hijauTua)),
                ),
              ]),
              const SizedBox(height: 12),
              Text('${data['judul'] ?? ''}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: WarnaRSIA.teksGelap, height: 1.35)),
              const SizedBox(height: 6),
              Text('${data['created_at'] ?? ''}'.split(' ').first, style: const TextStyle(fontSize: 11.5, color: WarnaRSIA.teksAbu)),
              const Divider(height: 26),
              // 'isi' = teks artikel (dipisah per baris supaya enak dibaca).
              Text('${data['isi'] ?? ''}', style: const TextStyle(fontSize: 14, height: 1.7, color: WarnaRSIA.teksGelap)),
              const SizedBox(height: 20),
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

  // Warna chip per kategori artikel (hanya tampilan, backend bebas).
  Color _warnaKategori(String k) {
    switch (k.toLowerCase()) {
      case 'hipertensi':
        return WarnaRSIA.merah;
      case 'diabetes':
        return Colors.orange;
      case 'gizi':
        return WarnaRSIA.hijau;
      case 'ibu-anak':
        return WarnaRSIA.biru;
      default:
        return WarnaRSIA.teksAbu;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Artikel Kesehatan')),
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
          : _artikel.isEmpty
          ? const Center(child: Text('Belum ada artikel edukasi.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _artikel.length,
        itemBuilder: (context, index) {
          final a = _artikel[index] as Map<String, dynamic>;
          final kategori = '${a['kategori'] ?? 'Umum'}';
          return InkWell(
            onTap: () => _bukaArtikel(a), // ketuk → ambil isi lengkap.
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
                    decoration: BoxDecoration(color: _warnaKategori(kategori).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.article, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${a['judul'] ?? '-'}',
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: WarnaRSIA.teksGelap, height: 1.35)),
                        const SizedBox(height: 4),
                        Text('${a['created_at'] ?? ''}'.split(' ').first,
                            style: const TextStyle(fontSize: 11, color: WarnaRSIA.teksAbu)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: _warnaKategori(kategori).withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                    child: Text(kategori, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: _warnaKategori(kategori))),
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