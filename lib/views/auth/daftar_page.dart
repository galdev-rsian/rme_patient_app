// ============================================================
//  daftar_page.dart — HALAMAN DAFTAR / AKTIVASI AKUN (BARU di v3)
//  Alur sesuai permintaan:
//    LANGKAH 1: pasien mengetik No. KTP lalu tekan "Cari NIK".
//        • NIK TIDAK ditemukan  → dialog: wajib mendaftar dulu ke RS.
//        • NIK ditemukan & SUDAH punya akun → dialog: silakan pakai MASUK.
//        • NIK ditemukan & BELUM punya akun → lanjut LANGKAH 2, dan
//          NAMA LENGKAP + NO. RM otomatis terisi dari server (permintaan no. 1).
//    LANGKAH 2: tampilkan data pasien (read-only) + soal CAPTCHA dari
//        server + kolom jawaban. Tekan "Verifikasi Data" → POST
//        /verifikasi-data → kalau cocok, server memberi verif_token dan
//        aplikasi membuka halaman "Buat Password".
//  File ini diletakkan di lib/pages/login/ (satu folder dengan login_page.dart).
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// Alamat API pusat: AppConfig.apiBaseUrl (mis. http://192.168.0.104:8000/api/pasien)
import '../../services/config.dart';
import '../../tema_rsia.dart'; // warna resmi RSIA untuk SnackBar error.
import 'buat_password_page.dart';

class DaftarPage extends StatefulWidget {
  const DaftarPage({super.key});

  @override
  State<DaftarPage> createState() => _DaftarPageState();
}

class _DaftarPageState extends State<DaftarPage> {
  // ===== "remote control" untuk Form langkah 1 (cari NIK) =====
  final _formKeyNik = GlobalKey<FormState>();

  // ===== wadah isi kotak teks =====
  final _nikCtrl = TextEditingController();      // No. KTP yang diketik pasien
  final _captchaCtrl = TextEditingController();  // jawaban captcha

  // ===== data yang berubah selama proses daftar =====
  int _step = 1;                 // 1 = cari NIK, 2 = verifikasi data
  bool _isLoading = false;       // tombol "Cari NIK"/"Verifikasi Data" berputar
  bool _captchaLoading = false;  // sedang mengambil soal captcha baru
  String _namaPasien = '';       // terisi otomatis dari server (langkah 1 → 2)
  String _noRm = '';             // terisi otomatis dari server (langkah 1 → 2)
  String _captchaId = '';        // ID soal captcha — ikut dikirim saat verifikasi
  String _captchaSoal = '';      // teks soal yang ditampilkan, mis. "7 + 5 = ?"

  @override
  void dispose() {
    // WAJIB membuang controller supaya tidak terjadi kebocoran memori.
    _nikCtrl.dispose();
    _captchaCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // LANGKAH 1: cari NIK → POST /api/pasien/cek-nik
  // ============================================================
  Future<void> _cariNik() async {
    if (!_formKeyNik.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/cek-nik'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'no_ktp': _nikCtrl.text.trim()}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['next_step'] == 'buat_password') {
        // NIK ditemukan & belum punya akun → isi otomatis + lanjut ke langkah 2.
        final pasien = data['pasien'] as Map<String, dynamic>;
        setState(() {
          _namaPasien = pasien['nm_pasien']?.toString() ?? '';
          _noRm = pasien['no_rkm_medis']?.toString() ?? '';
          _step = 2;
        });
        // Ambil soal captcha pertama dari server.
        _muatCaptcha();
      } else if (response.statusCode == 200 && data['next_step'] == 'password') {
        // NIK ditemukan tapi SUDAH punya akun → suruh pakai tombol MASUK.
        _showDialogInfo('Sudah punya akun', data['message'] ?? 'NIK ini sudah pernah membuat password. Silakan masuk dengan tombol MASUK.');
      } else {
        // NIK TIDAK ditemukan (404) → pesan wajib mendaftar ke RS (permintaan no. 2).
        _showDialogInfo(
          'NIK tidak ditemukan',
          data['message'] ??
              'NIK tidak terdaftar sebagai pasien RS. Anda wajib mendaftar terlebih dahulu '
              'sebagai pasien di bagian pendaftaran RS, setelah itu kembali ke aplikasi.',
        );
      }
    } catch (e) {
      _showError('Tidak dapat terhubung ke server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // Ambil soal captcha → GET /api/pasien/captcha
  // Dipanggil saat masuk langkah 2 & setiap kali tombol muat-ulang ditekan
  // (soal captcha bersifat SEKALI PAKAI di server).
  // ============================================================
  Future<void> _muatCaptcha() async {
    setState(() => _captchaLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/captcha'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['captcha_id'] != null) {
        setState(() {
          _captchaId = data['captcha_id'].toString();
          _captchaSoal = data['pertanyaan']?.toString() ?? '';
          _captchaCtrl.clear(); // jawaban lama hangus, kolom dikosongkan
        });
      } else {
        _showError(data['message'] ?? 'Gagal memuat soal captcha.');
      }
    } catch (e) {
      _showError('Tidak dapat terhubung ke server (captcha).');
    } finally {
      if (mounted) setState(() => _captchaLoading = false);
    }
  }

  // ============================================================
  // LANGKAH 2 tombol "Verifikasi Data" → POST /api/pasien/verifikasi-data
  // Berhasil → server kirim verif_token → buka BuatPasswordPage.
  // ============================================================
  Future<void> _verifikasiData() async {
    if (_captchaCtrl.text.trim().isEmpty) {
      _showError('Jawaban captcha wajib diisi.');
      return;
    }
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/verifikasi-data'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        // Kirim PERSIS data yang diminta backend:
        // no_ktp + captcha_id + captcha_jawaban.
        body: jsonEncode({
          'no_ktp': _nikCtrl.text.trim(),
          'captcha_id': _captchaId,
          'captcha_jawaban': _captchaCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['verif_token'] != null) {
        if (!mounted) return;
        // pushReplacement = halaman Daftar diganti halaman Buat Password,
        // sehingga tombol back tidak kembali ke keadaan verifikasi lama.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BuatPasswordPage(
              noKtp: _nikCtrl.text.trim(),
              verifToken: data['verif_token'].toString(),
              namaPasien: _namaPasien,
              noRm: _noRm,
            ),
          ),
        );
      } else {
        // Verifikasi gagal (captcha salah/kedaluwarsa/akun sudah ada).
        _showError(data['message'] ?? 'Verifikasi gagal.');
        // Soal captcha di server sudah hangus → minta soal baru otomatis.
        _muatCaptcha();
      }
    } catch (e) {
      _showError('Tidak dapat terhubung ke server.');
      _muatCaptcha();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== helper: SnackBar error =====
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: WarnaRSIA.merah),
    );
  }

  // ===== helper: dialog informasi (dipakai untuk pesan "wajib daftar ke RS") =====
  Future<void> _showDialogInfo(String judul, String pesan) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(judul),
        content: Text(pesan, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ===== TAMPILAN =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar / Aktifkan Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _step == 1 ? _buildLangkahCariNik() : _buildLangkahVerifikasi(),
      ),
    );
  }

  // ------------------------------------------------------------
  // LANGKAH 1 — form cari NIK
  // ------------------------------------------------------------
  Widget _buildLangkahCariNik() {
    return Form(
      key: _formKeyNik,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info singkat alur pendaftaran.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.35)),
            ),
            child: const Text(
              'Aktivasi akun HANYA untuk pasien yang sudah pernah terdaftar di RS. '
              'Masukkan No. KTP Anda — jika ditemukan, nama lengkap dan No. Rekam Medis '
              'akan terisi otomatis.',
              style: TextStyle(fontSize: 12.5, height: 1.5),
            ),
          ),

          // Kolom No. KTP — keyboard angka.
          TextFormField(
            controller: _nikCtrl,
            decoration: const InputDecoration(
              labelText: 'No. KTP (NIK)',
              prefixIcon: Icon(Icons.badge),
            ),
            keyboardType: TextInputType.number,
            // validator: kembalikan TEKS = pesan error; null = lolos.
            validator: (v) => v == null || v.trim().isEmpty ? 'No. KTP wajib diisi' : null,
          ),
          const SizedBox(height: 20),

          // Tombol cari NIK — nonaktif saat loading supaya tidak diklik 2x.
          ElevatedButton(
            onPressed: _isLoading ? null : _cariNik,
            child: _isLoading
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                : const Text('Cari NIK'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // LANGKAH 2 — data pasien (read-only) + captcha + verifikasi
  // ------------------------------------------------------------
  Widget _buildLangkahVerifikasi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kartu data pasien — terisi OTOMATIS dari server, TIDAK bisa diedit
        // (read-only) supaya tidak ada yang mengganti identitas orang lain.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data pasien ditemukan', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              const Text('Nama Lengkap', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
              Text(_namaPasien, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('No. Rekam Medis', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
              Text(_noRm, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        // Kotak soal captcha + tombol muat-ulang.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _captchaLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4))
                    // Soal ditampilkan dengan huruf besar & jarang (letterspacing)
                    // supaya mudah dibaca pasien lansia.
                    : Text(_captchaSoal, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ),
              // Tombol muat-ulang: minta soal baru kalau tidak terbaca /
              // soal lama sudah hangus setelah jawaban salah.
              IconButton(
                tooltip: 'Muat ulang soal',
                onPressed: _captchaLoading ? null : _muatCaptcha,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),

        // Kolom jawaban captcha — hasil penjumlahan selalu angka.
        TextFormField(
          controller: _captchaCtrl,
          decoration: const InputDecoration(
            labelText: 'Jawaban captcha',
            prefixIcon: Icon(Icons.verified_user),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),

        // Tombol "Verifikasi Data" (permintaan no. 1) — memanggil _verifikasiData.
        ElevatedButton(
          onPressed: _isLoading ? null : _verifikasiData,
          child: _isLoading
              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
              : const Text('Verifikasi Data'),
        ),
        const SizedBox(height: 8),

        // Kembali ke langkah 1 (ganti NIK) — juga reset data yang terisi.
        TextButton(
          onPressed: _isLoading
              ? null
              : () => setState(() {
                    _step = 1;
                    _namaPasien = '';
                    _noRm = '';
                    _captchaSoal = '';
                    _captchaId = '';
                    _captchaCtrl.clear();
                  }),
          child: const Text('Bukan Anda? Ganti No. KTP'),
        ),
      ],
    );
  }
}
