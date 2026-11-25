// ============================================================
//  buat_password_page.dart — HALAMAN BUAT PASSWORD AWAL (BARU di v3)
//  Tahap TERAKHIR alur Daftar. Halaman ini MENERIMA 4 data dari
//  DaftarPage: noKtp, verifToken, namaPasien, noRm.
//
//  SINKRON DENGAN BACKEND (PasienAuthController@buatPassword):
//    Endpoint = POST /api/pasien/buat-password
//    Field yang dikirim PERSIS sama dengan validasi backend:
//      'no_ktp'                → NIK pasien
//      'verif_token'           → tiket hasil "Verifikasi Data" (wajib!)
//      'password'              → wajib, minimal 8 karakter
//      'password_confirmation' → harus SAMA dengan password
//    Kalau berhasil, server langsung menganggap pasien login:
//    respons berisi token + data pasien → simpan & masuk Dashboard.
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/config.dart';
import '../../models/pasien_model.dart';
import '../dashboard/dashboard_page.dart';

class BuatPasswordPage extends StatefulWidget {
  // Data yang diterima dari DaftarPage — diakses dengan awalan "widget."
  final String noKtp;       // NIK yang tadi diverifikasi
  final String verifToken;  // tiket sekali pakai dari endpoint verifikasi-data
  final String namaPasien;  // tampil di kartu info supaya pasien yakin
  final String noRm;        // no. RM yang tadi ditemukan server

  const BuatPasswordPage({
    super.key,
    required this.noKtp,
    required this.verifToken,
    required this.namaPasien,
    required this.noRm,
  });

  @override
  State<BuatPasswordPage> createState() => _BuatPasswordPageState();
}

class _BuatPasswordPageState extends State<BuatPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true; // tombol mata untuk lihat/sembunyikan isi

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ===== LOGIKA: simpan password → POST /api/pasien/buat-password =====
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/buat-password'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'no_ktp': widget.noKtp,
          'verif_token': widget.verifToken,
          'password': _passCtrl.text,
          // Nama key "..._confirmation" = aturan Laravel "same:password".
          'password_confirmation': _confirmCtrl.text,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // Berhasil → server menganggap ini LOGIN: simpan token & profil.
        final token = data['token'] as String;
        final pasien = Pasien.fromJson(data['pasien'] as Map<String, dynamic>);

        final sp = await SharedPreferences.getInstance();
        await sp.setString('auth_token', token);
        await sp.setString('pasien_name', pasien.nmPasien);
        await sp.setString('pasien_no_rm', pasien.noRkmMedis);

        if (!mounted) return;
        // pushReplacement = halaman Buat Password diganti Dashboard;
        // tombol back tidak bisa kembali ke halaman pendaftaran lagi.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DashboardPage(pasien: pasien, token: token)),
        );
      } else {
        // Gagal: verif_token kedaluwarsa (419), konfirmasi tidak sama (422),
        // atau akun ternyata sudah ada (409). Tampilkan alasan pertama.
        String pesan = data['message'] ?? 'Gagal membuat password';
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          pesan = (errors.values.first as List).first.toString();
        }
        _showError(pesan);
      }
    } catch (e) {
      _showError('Tidak dapat terhubung ke server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== helper: SnackBar error =====
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ===== TAMPILAN =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Password')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kartu info: pasien yakin akun ini miliknya (data hasil verifikasi).
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.4)),
                ),
                child: Text(
                  'Data terverifikasi:\n'
                  'Nama  : ${widget.namaPasien}\n'
                  'No. RM : ${widget.noRm}\n\n'
                  'Buat password untuk melindungi akun Anda. Gunakan kombinasi '
                  'huruf dan angka yang mudah Anda ingat namun sulit ditebak.',
                  style: const TextStyle(fontSize: 12.5, height: 1.5),
                ),
              ),

              // Kolom 1: password baru — sama dengan aturan 'min:8' di backend.
              TextFormField(
                controller: _passCtrl,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  helperText: 'Minimal 8 karakter',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (v) => v == null || v.length < 8 ? 'Min. 8 karakter' : null,
              ),
              const SizedBox(height: 16),

              // Kolom 2: harus SAMA — sama dengan 'same:password' di backend.
              TextFormField(
                controller: _confirmCtrl,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (v) => v != _passCtrl.text ? 'Tidak cocok dengan password di atas' : null,
              ),
              const SizedBox(height: 24),

              // Tombol simpan — nonaktif saat loading.
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                    : const Text('Simpan Password & Masuk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
