// ============================================================
//  pendaftaran_page.dart — Modul "Pendaftaran Online" — SUDAH
//  TERHUBUNG KE API (bukan data contoh lagi!).
//
//  SINKRON DENGAN BACKEND (3 endpoint, urutan pakainya):
//  1. GET /api/pasien/poli/daftar-poli  → isi dropdown POLI
//     (PasienPendaftaranController@daftarPoli, tabel poliklinik)
//  2. GET /api/pasien/poli/jadwal?kd_poli=..&tgl=..
//     → isi dropdown DOKTER + jam + SISA KUOTA
//     (PasienPendaftaranController@jadwal, tabel jadwal+dokter;
//      sisa_kuota dihitung server: kuota - yang sudah daftar)
//  3. POST /api/pasien/pendaftaran  { kd_poli, kd_dokter, tgl_periksa }
//     → simpan ke tabel reg_periksa (PasienPendaftaranController@store).
//     Server yang menghitung: no_reg, no_rawat, Baru/Lama, umur,
//     kd_pj (cara bayar) — aplikasi TIDAK mengirim hal-hal itu.
// ============================================================
import 'package:flutter/material.dart';
import '../../tema_rsia.dart';
import '../../services/api_service.dart';

class PendaftaranPage extends StatefulWidget {
  final String token;

  const PendaftaranPage({super.key, required this.token});

  @override
  State<PendaftaranPage> createState() => _PendaftaranPageState();
}

class _PendaftaranPageState extends State<PendaftaranPage> {
  // ===== Data dari server =====
  bool _memuatPoli = true;
  String? _error;
  List _daftarPoli = [];   // isi: { kd_poli, nm_poli }
  List _daftarJadwal = []; // isi: { kd_dokter, nm_dokter, jam_mulai, jam_selesai, kuota, terdaftar, sisa_kuota }

  // ===== Data yang sedang DIPILIH user =====
  String? _kdPoli;      // kode poli terpilih (dikirim ke server, BUKAN namanya!)
  String? _nmPoli;      // nama poli (hanya untuk tampilan)
  Map<String, dynamic>? _jadwalTerpilih; // baris jadwal (dokter+jam) terpilih
  DateTime? _tanggal;   // tanggal pilihan dari kalender

  bool _mengirim = false; // true saat POST /pendaftaran sedang berjalan.

  @override
  void initState() {
    super.initState();
    _muatPoli();
  }

  // ===== Langkah 1: ambil daftar poliklinik dari server =====
  Future<void> _muatPoli() async {
    setState(() { _memuatPoli = true; _error = null; });
    try {
      // → GET /api/pasien/poli/daftar-poli
      final hasil = await ApiService.get('/poli/daftar-poli');
      if (!mounted) return;
      setState(() { _daftarPoli = (hasil['data'] as List?) ?? []; _memuatPoli = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _memuatPoli = false; });
    }
  }

  // ===== Kalender pilih tanggal =====
  Future<void> _pilihTanggal() async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(), // tidak boleh masa lalu (server juga menolak).
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (hasil == null) return; // user menutup kalender tanpa memilih.
    setState(() {
      _tanggal = hasil;
      _jadwalTerpilih = null; // reset pilihan dokter — jadwal harus dimuat ulang.
      _daftarJadwal = [];
    });
    await _muatJadwal(); // poli + tanggal sudah ada → muat jadwalnya.
  }

  // ===== Langkah 2: ambil jadwal dokter (poli + tanggal terpilih) =====
  Future<void> _muatJadwal() async {
    if (_kdPoli == null || _tanggal == null) return; // butuh keduanya dulu.
    setState(() { _memuatPoli = true; _error = null; }); // pakai spinner yang sama.
    try {
      // Tanggal diformat yyyy-MM-dd — format yang diminta backend.
      final tgl = '${_tanggal!.year.toString().padLeft(4, '0')}-${_tanggal!.month.toString().padLeft(2, '0')}-${_tanggal!.day.toString().padLeft(2, '0')}';
      // → GET /api/pasien/poli/jadwal?kd_poli=..&tgl=..
      //   (query string = data tambahan di belakang tanda tanya URL)
      final hasil = await ApiService.get('/poli/jadwal?kd_poli=$_kdPoli&tgl=$tgl');
      if (!mounted) return;
      setState(() { _daftarJadwal = (hasil['data'] as List?) ?? []; _memuatPoli = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _memuatPoli = false; });
    }
  }

  // ===== Langkah 3: kirim pendaftaran ke server =====
  Future<void> _kirim() async {
    // Validasi: poli, dokter (via jadwal), dan tanggal harus sudah dipilih.
    if (_kdPoli == null || _jadwalTerpilih == null || _tanggal == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi poli, tanggal, dan dokter dulu.'), backgroundColor: WarnaRSIA.merah));
      return;
    }
    setState(() => _mengirim = true);
    try {
      final tgl = '${_tanggal!.year.toString().padLeft(4, '0')}-${_tanggal!.month.toString().padLeft(2, '0')}-${_tanggal!.day.toString().padLeft(2, '0')}';
      // → POST /api/pasien/pendaftaran
      //   Kirim HANYA 3 field — sisanya (no_reg, Baru/Lama, umur, cara
      //   bayar) dihitung server dari data yang sudah ada di database.
      final hasil = await ApiService.post('/pendaftaran', {
        'kd_poli': _kdPoli,
        'kd_dokter': _jadwalTerpilih!['kd_dokter'],
        'tgl_periksa': tgl,
      });
      if (!mounted) return;
      setState(() => _mengirim = false);
      // Sukses → server mengirim data konfirmasi di key 'data'.
      final data = hasil['data'] as Map<String, dynamic>?;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          icon: const Icon(Icons.check_circle, color: WarnaRSIA.hijau, size: 44),
          title: const Text('Pendaftaran Berhasil'),
          content: data == null
              ? const Text('Silakan datang sesuai jadwal.')
              : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Poli: ${data['nm_poli']}'),
              Text('Hari/Tanggal: ${data['hari']}, ${data['tgl_periksa']}'),
              Text('Jam: ${data['jam']}'),
              Text('No. Registrasi: ${data['no_reg']}'),
              Text('No. Rawat: ${data['no_rawat']}'),
              const SizedBox(height: 8),
              const Text('Notifikasi juga dikirim ke menu Notifikasi Anda.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Baik, terima kasih'),
            ),
          ],
        ),
      );
      // Reset pilihan supaya form siap untuk pendaftaran berikutnya.
      setState(() { _jadwalTerpilih = null; _tanggal = null; _daftarJadwal = []; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _mengirim = false);
      // Pesan error dari server sudah ramah, mis:
      // "Kuota pendaftaran untuk jadwal ini sudah penuh."
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: WarnaRSIA.merah),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pendaftaran Online')),
      body: _memuatPoli
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: WarnaRSIA.teksAbu, fontSize: 13)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _muatPoli, child: const Text('Coba Lagi')),
        ]),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ----- Kartu penjelas singkat di atas form -----
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: WarnaRSIA.garis)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: WarnaRSIA.biru),
                  SizedBox(width: 12),
                  Expanded(child: Text('Pilih poli, tanggal kunjungan, lalu dokter & jam praktiknya. Datang 15 menit sebelum jam praktik.', style: TextStyle(fontSize: 12.5, color: WarnaRSIA.teksAbu))),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ----- Dropdown pilih POLI (dari tabel poliklinik) -----
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: WarnaRSIA.garis)),
              child: DropdownButtonFormField<String>(
                initialValue: _kdPoli,
                decoration: const InputDecoration(labelText: 'Poli Tujuan', border: InputBorder.none, filled: false),
                isExpanded: true,
                // value = kd_poli (kode, dikirim ke server);
                // label = nm_poli (nama, yang dibaca user).
                items: _daftarPoli.map((p) {
                  p as Map<String, dynamic>;
                  return DropdownMenuItem<String>(value: '${p['kd_poli']}', child: Text('${p['nm_poli']}'));
                }).toList(),
                onChanged: (pilihanBaru) {
                  setState(() {
                    _kdPoli = pilihanBaru;
                    _nmPoli = _daftarPoli
                        .firstWhere((p) => '${(p as Map)['kd_poli']}' == pilihanBaru,
                        orElse: () => <String, dynamic>{'nm_poli': ''})
                    ['nm_poli'];
                    _jadwalTerpilih = null; // reset dokter
                    _daftarJadwal = [];
                    // Poli berubah → jika tanggal sudah dipilih, muat jadwal baru.
                  });
                  if (_tanggal != null) _muatJadwal();
                },
              ),
            ),
            const SizedBox(height: 12),

            // ----- Pemilih TANGGAL (kotak yang diketuk → kalender) -----
            InkWell(
              onTap: _pilihTanggal,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: WarnaRSIA.garis)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: WarnaRSIA.hijau),
                    const SizedBox(width: 12),
                    Text(
                      _tanggal == null ? 'Pilih tanggal kunjungan' : '${_tanggal!.day}/${_tanggal!.month}/${_tanggal!.year}',
                      style: TextStyle(color: _tanggal == null ? WarnaRSIA.teksAbu : WarnaRSIA.teksGelap, fontSize: 14.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ----- Dropdown DOKTER + JAM (dari tabel jadwal; ada sisa kuota) -----
            // Muncul setelah poli & tanggal dipilih. Setiap pilihan =
            // satu baris jadwal (dokter + jam + sisa kuota).
            if (_kdPoli != null && _tanggal != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: WarnaRSIA.garis)),
                child: _daftarJadwal.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Tidak ada jadwal dokter pada poli & tanggal ini. Coba tanggal lain.',
                      style: TextStyle(fontSize: 12.5, color: WarnaRSIA.teksAbu)),
                )
                    : DropdownButtonFormField<Map<String, dynamic>>(
                  initialValue: _jadwalTerpilih,
                  decoration: const InputDecoration(labelText: 'Dokter & Jam Praktik', border: InputBorder.none, filled: false),
                  isExpanded: true,
                  items: _daftarJadwal.map((j) {
                    j as Map<String, dynamic>;
                    // Contoh label: "dr. Budi (08:00-12:00) • sisa 5 dari 20"
                    final label = '${j['nm_dokter']} (${j['jam_mulai']}-${j['jam_selesai']}) • sisa ${j['sisa_kuota']}';
                    return DropdownMenuItem<Map<String, dynamic>>(value: j, child: Text(label, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (pilihan) => setState(() => _jadwalTerpilih = pilihan),
                ),
              ),
              if (_jadwalTerpilih != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text('Dipilih: ${_jadwalTerpilih!['nm_dokter']} di $_nmPoli, kuota tersisa ${_jadwalTerpilih!['sisa_kuota']} pasien.',
                      style: const TextStyle(fontSize: 12, color: WarnaRSIA.hijauTua, fontWeight: FontWeight.w600)),
                ),
            ],
            const SizedBox(height: 20),

            // ----- Tombol kirim -----
            ElevatedButton(
              // Nonaktif saat mengirim agar tidak terkirim dua kali.
              onPressed: _mengirim ? null : _kirim,
              child: _mengirim
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                  : const Text('Kirim Pendaftaran'),
            ),
            const SizedBox(height: 10),
            const Text('Nomor registrasi & status Baru/Lama dihitung otomatis oleh sistem RS.',
                textAlign: TextAlign.center, style: TextStyle(color: WarnaRSIA.teksAbu, fontSize: 11.5)),
          ],
        ),
      ),
    );
  }
}