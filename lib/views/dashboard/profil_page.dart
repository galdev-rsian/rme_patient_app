// ============================================================
//  profil_page.dart — Menu "Profil Saya" — dengan TOMBOL MUAT
//  ULANG dari server.
//
//  SINKRON DENGAN BACKEND:
//  Endpoint = GET /api/pasien/me (PasienAuthController@me).
//  Data profil SUDAH dibawa sejak login (key 'pasien' di jawaban
//  login), jadi halaman pertama kali buka langsung tampil tanpa
//  menunggu internet. Tombol "Muat ulang" memanggil GET /me untuk
//  memastikan data terbaru (mis. alamat/telepon sudah diperbarui
//  petugas di aplikasi web RME).
// ============================================================
import 'package:flutter/material.dart';
import '../../models/pasien_model.dart';
import '../../tema_rsia.dart';
import '../../services/api_service.dart';

class ProfilPage extends StatefulWidget {
  final Pasien pasien; // data dari halaman login (langsung tampil).

  const ProfilPage({super.key, required this.pasien});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  late Pasien _pasien;      // salinan data profil yang sedang ditampilkan.
  bool _menyegarkan = false; // true saat GET /me sedang berjalan.

  @override
  void initState() {
    super.initState();
    _pasien = widget.pasien;
  }

  // ===== Muat ulang profil dari server (GET /me) =====
  Future<void> _muatUlang() async {
    setState(() => _menyegarkan = true);
    try {
      // → GET /api/pasien/me — jawaban: { status, message, pasien: {...} }
      final hasil = await ApiService.get('/me');
      if (!mounted) return;
      setState(() {
        // jsonDecode mengembalikan Map → ubah jadi objek Pasien lewat model.
        _pasien = Pasien.fromJson(hasil['pasien'] as Map<String, dynamic>);
        _menyegarkan = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil diperbarui dari server.'), backgroundColor: WarnaRSIA.hijau),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _menyegarkan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: WarnaRSIA.merah),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Pasien')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tombol muat ulang di atas daftar — contoh pemanggilan GET /me.
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _menyegarkan ? null : _muatUlang, // nonaktif saat sedang memuat.
              icon: _menyegarkan
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh, size: 18),
              label: const Text('Muat ulang dari server', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ),
          ),
          // ListTile = baris standar: judul di atas, isi di bawahnya.
          ListTile(title: const Text('No. Rekam Medis'), subtitle: Text(_pasien.noRkmMedis)),
          ListTile(title: const Text('Nama Lengkap'), subtitle: Text(_pasien.nmPasien)),
          // '??' = nilai cadangan: jika noKtp null (kosong), tampilkan '-'.
          ListTile(title: const Text('No. KTP'), subtitle: Text(_pasien.noKtp ?? '-')),
          // Ternary: jika jk == 'L' tulis Laki-laki, selain itu Perempuan.
          ListTile(title: const Text('Jenis Kelamin'), subtitle: Text(_pasien.jk == 'L' ? 'Laki-laki' : 'Perempuan')),
          ListTile(title: const Text('Tanggal Lahir'), subtitle: Text(_pasien.tglLahir ?? '-')),
          ListTile(title: const Text('Alamat'), subtitle: Text(_pasien.alamat ?? '-')),
          ListTile(title: const Text('No. Telepon'), subtitle: Text(_pasien.noTlp ?? '-')),
          ListTile(title: const Text('Email'), subtitle: Text(_pasien.email ?? '-')),
        ],
      ),
    );
  }
}