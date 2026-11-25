// ============================================================
//  change_password_page.dart — Ganti password SETELAH login.
//  VERSI 2: disesuaikan dengan alur baru (v4 backend):
//    • TIDAK ada lagi password default (pasien123456) — semua akun baru
//      membuat password sendiri lewat halaman Daftar. Halaman ini sekarang
//      dipakai untuk DUA kasus:
//        1. Akun sisa sistem lama yang masih punya tanda
//           must_change_password = true (muncul otomatis setelah login).
//        2. Pasien ingin mengganti password kapan saja dari menu profil.
//
//  SINKRON DENGAN BACKEND:
//    Endpoint = POST /api/pasien/change-password (butuh token Bearer).
//    Backend HANYA memvalidasi dua field ini:
//      'new_password'              → wajib, minimal 8 karakter
//      'new_password_confirmation' → harus SAMA dengan new_password
//    Maka halaman ini juga hanya mengirim dua field itu — apa yang
//    dikirim aplikasi = persis apa yang diminta backend.
// ============================================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/config.dart'; // untuk AppConfig.apiBaseUrl
import '../../models/pasien_model.dart';
import '../dashboard/dashboard_page.dart';

class ChangePasswordPage extends StatefulWidget {
  // Widget ini MENERIMA 2 data dari halaman sebelumnya (LoginPage):
  final Pasien pasien; // data pasien yang barusan login.
  final String token;  // "kartu akses" dari server, ikut disertakan di setiap request.

  const ChangePasswordPage({super.key, required this.pasien, required this.token});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  // Data yang diterima dari widget induk dipanggil dengan awalan "widget." :
  // widget.pasien, widget.token
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return; // validasi form dulu.
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        // → POST /api/pasien/change-password
        Uri.parse('${AppConfig.apiBaseUrl}/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Authorization: Bearer <token> = cara standar memberi tahu server
          // "aku sudah login". Token didapat saat login berhasil tadi.
          'Authorization': 'Bearer ${widget.token}',
        },
        // Field yang dikirim PERSIS sama dengan validasi di controller:
        body: jsonEncode({
          'new_password': _newCtrl.text,
          // Nama key "..._confirmation" = aturan Laravel untuk validasi
          // otomatis "harus sama dengan new_password".
          'new_password_confirmation': _confirmCtrl.text,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200) {
        if (!mounted) return; // halaman masih terbuka? cek dulu setelah await.
        // Sukses → ganti halaman ini dengan DashboardPage.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DashboardPage(pasien: widget.pasien, token: widget.token)),
        );
      } else {
        // Gagal (mis. konfirmasi tidak cocok / password kurang dari 8 karakter).
        // Backend mengirim {"status": false, "message": "Validasi gagal", "errors": {...}}
        String pesan = data['message'] ?? 'Gagal mengganti password';
        // errors = daftar alasan per field — tampilkan alasan pertamanya
        // supaya pemula mudah membaca kenapa ditolak.
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          pesan = (errors.values.first as List).first.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
      }
    } catch (e) {
      // Error koneksi / server mati.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan koneksi')));
    } finally {
      if (mounted) setState(() => _isLoading = false); // matikan loading apa pun hasilnya.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ganti Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Info singkat: kenapa halaman ini muncul & tanpa kolom "password lama".
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.4)),
                ),
                child: const Text(
                  'Buat password baru yang mudah Anda ingat namun sulit ditebak. '
                  'Gunakan kombinasi huruf dan angka (minimal 8 karakter).',
                  style: TextStyle(fontSize: 12.5, height: 1.5),
                ),
              ),
              // Kolom 1: password baru, minimal 8 karakter — sama dengan
              // aturan 'new_password' => 'required|min:8' di backend.
              TextFormField(controller: _newCtrl, decoration: const InputDecoration(labelText: 'Password Baru'), obscureText: true, validator: (v) => v!.length < 8 ? 'Min. 8 karakter' : null),
              const SizedBox(height: 16),
              // Kolom 2: harus SAMA dengan isi kolom password baru — sama
              // dengan 'new_password_confirmation' => 'same:new_password'.
              TextFormField(controller: _confirmCtrl, decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru'), obscureText: true, validator: (v) => v != _newCtrl.text ? 'Tidak cocok' : null),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _isLoading ? null : _submit, child: const Text('Simpan Password Baru')),
            ],
          ),
        ),
      ),
    );
  }
}
