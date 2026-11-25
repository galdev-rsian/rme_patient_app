// ============================================================
//  login_page.dart — Halaman masuk aplikasi (No. KTP + Password).
//  VERSI 3: punya DUA tombol sesuai alur baru:
//    • MASUK  → form No. KTP + password (alur login biasa).
//    • DAFTAR → membuka DaftarPage: cari NIK → verifikasi captcha
//               → buat password pertama.
//  Logika API MASUK sama persis dengan versi sebelumnya; hanya
//  ditambah tombol Daftar dan import DaftarPage.
// ============================================================

// dart:convert = bawaan Dart, berisi jsonEncode (objek → teks JSON)
// dan jsonDecode (teks JSON → objek) untuk berkomunikasi dengan API.
import 'dart:convert';
import 'package:flutter/material.dart';
// package:http = untuk mengirim permintaan ke server (flutter pub add http).
import 'package:http/http.dart' as http;
// package:shared_preferences = penyimpanan kecil di HP untuk token.
import 'package:shared_preferences/shared_preferences.dart';
// Alamat API dari file pengaturan pusat (config.dart).
import '../../services/config.dart';
import '../../tema_rsia.dart'; // warna & gradien resmi RSIA.
import '../../models/pasien_model.dart';
import '../dashboard/dashboard_page.dart';
import 'change_password_page.dart';
// (BARU) Halaman pendaftaran/aktivasi akun — file daftar_page.dart
// berada di folder yang sama (lib/pages/login/).
import 'daftar_page.dart';

// StatefulWidget = widget yang PUNYA data berubah-ubah (isi form, status
// loading, dst). Berbeda dengan StatelessWidget yang tampilannya statis.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// Class ini menyimpan SEMUA data berubah + tampilan halaman login.
// Tanda _ di awal nama (_LoginPageState) artinya privat, hanya dipakai di file ini.
class _LoginPageState extends State<LoginPage> {
  // GlobalKey<FormState> = "remote control" untuk Form di bawah,
  // dipakai untuk menjalankan validasi sekaligus: _formKey.currentState!.validate()
  final _formKey = GlobalKey<FormState>();

  // TextEditingController = wadah untuk MEMBACA isi kotak teks.
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;      // true saat menunggu jawaban server → tombol berputar.
  bool _obscurePassword = true; // true = password tampil sebagai titik-titik (•••).

  // dispose() dipanggil otomatis saat halaman ditutup permanen.
  // WAJIB membuang controller di sini supaya tidak terjadi kebocoran memori.
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===== LOGIKA MASUK (sama seperti versi 1) =====
  // Future<void> + async = fungsi yang bisa "menunggu" proses internet
  // TANPA membekukan tampilan. await = berhenti di baris ini sampai selesai.
  Future<void> _handleLogin() async {
    // Jalankan validasi form. Jika ada kolom kosong, hentikan di sini.
    if (!_formKey.currentState!.validate()) return;

    // setState() memberi tahu Flutter: "data berubah, gambar ulang tampilan!".
    setState(() => _isLoading = true);

    try {
      // Kirim data login ke server dengan metode POST.
      final response = await http.post(
        // → alamat penuhnya: POST /api/pasien/login (PasienAuthController@login)
        Uri.parse('${AppConfig.apiBaseUrl}/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        // jsonEncode mengubah Map menjadi teks JSON yang dikirim ke Laravel:
        // {"username":"320123...","password":"rahasia123"}
        body: jsonEncode({
          'username': _usernameController.text.trim(), // trim() = buang spasi di ujung.
          'password': _passwordController.text,
        }),
        // Batas tunggu 15 detik supaya aplikasi tidak "menggantung" selamanya.
      ).timeout(const Duration(seconds: 15));

      // Ubah jawaban server (teks JSON) menjadi Map yang bisa dibaca Dart.
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // statusCode 200 = sukses menurut standar HTTP.
      if (response.statusCode == 200) {
        final token = data['token'] as String;
        // Bendera dari server: true jika password masih perlu diganti (akun lama).
        final mustChangePassword = data['must_change_password'] as bool? ?? false;
        // Ubah JSON pasien menjadi objek Pasien lewat model.
        final pasien = Pasien.fromJson(data['pasien'] as Map<String, dynamic>);

        // Simpan token + identitas pasien ke penyimpanan lokal HP.
        final sp = await SharedPreferences.getInstance();
        await sp.setString('auth_token', token);
        await sp.setString('pasien_name', pasien.nmPasien);
        await sp.setString('pasien_no_rm', pasien.noRkmMedis);

        // mounted = cek "apakah halaman ini masih terbuka?" — WAJIB setelah await.
        if (!mounted) return;

        if (mustChangePassword) {
          // Akun sisa sistem lama → paksa ganti password dulu.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => ChangePasswordPage(pasien: pasien, token: token)),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => DashboardPage(pasien: pasien, token: token)),
          );
        }
      } else {
        // Server menolak login (password salah, NIK tidak ada, dst.).
        // Catatan: kalau server mengirim next_step = "buat_password", pesan
        // dari server sudah menyarankan pasien menekan tombol DAFTAR.
        _showError(data['message'] ?? 'Login gagal');
      }
    } catch (e) {
      // Blok catch dijalankan jika terjadi error (server mati, tanpa internet, dll).
      _showError('Tidak dapat terhubung ke server.');
    } finally {
      // finally SELALU dijalankan (sukses maupun gagal): matikan animasi loading.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper kecil untuk menampilkan pesan error berupa SnackBar.
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: WarnaRSIA.merah),
    );
  }

  // ===== TAMPILAN (header gradien + kartu form + tombol Daftar) =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // Membuat konten bisa di-scroll — mencegah error "overflow" saat keyboard muncul.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // melebar penuh.
          children: [
            // ===== HEADER GRADASI RSIA (hijau → biru, sudut bawah melengkung) =====
            Container(
              decoration: const BoxDecoration(
                gradient: gradasiRSIA,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 34),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: 18),
                    // Lingkaran putih berisi logo RSIA (dari assets/images/logo.png).
                    Container(
                      width: 92,
                      height: 92,
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)]),
                      child: Image.asset('assets/images/logo.png'),
                    ),
                    const SizedBox(height: 14),
                    const Text('Portal Pasien', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("RSI 'Aisyiyah Nganjuk", style: TextStyle(color: Colors.white70, fontSize: 14.5)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white38)),
                      child: const Text('Modern  \u2022  Nyaman  \u2022  Berkesan', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                    ),
                  ],
                ),
              ),
            ),

            // Kartu form melayang menumpuk header gradien.
            Transform.translate(
              offset: const Offset(0, -26),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Selamat Datang Kembali', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: WarnaRSIA.teksGelap)),
                        const SizedBox(height: 6),
                        const Text('Masuk untuk mengakses rekam medis elektronik Anda.', style: TextStyle(color: WarnaRSIA.teksAbu, fontSize: 13.5)),
                        const SizedBox(height: 24),

                        // Kolom No. KTP — keyboard angka.
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(labelText: 'No. KTP', prefixIcon: Icon(Icons.badge)),
                          keyboardType: TextInputType.number,
                          // validator: kembalikan TEKS = pesan error; null = lolos.
                          validator: (v) => v == null || v.isEmpty ? 'No. KTP wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),

                        // Kolom password dengan tombol mata.
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (v) => v == null || v.isEmpty ? 'Password wajib diisi' : null,
                        ),

                        // "Lupa password?" rata kanan.
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan hubungi petugas CS RS untuk reset password.')));
                            },
                            child: const Text('Lupa password?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ===== TOMBOL MASUK =====
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                              : const Text('Masuk'),
                        ),
                        const SizedBox(height: 12),

                        // ===== TOMBOL DAFTAR (BARU di versi 3) =====
                        // OutlinedButton = tombol garis (bukan solid), gaya untuk
                        // aksi sekunder di bawah tombol utama. Menekannya membuka
                        // DaftarPage: cari NIK → captcha → verifikasi → buat password.
                        OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const DaftarPage()),
                                  );
                                },
                          icon: const Icon(Icons.person_add_alt_1, size: 20),
                          label: const Text('Daftar / Buat Password Pertama'),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'NIK Anda tidak ditemukan saat mendaftar? '
                          'Datang langsung ke bagian pendaftaran RS untuk mendaftar sebagai pasien.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: WarnaRSIA.teksAbu, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Footer: logo horizontal RSIA (rsia.png) + tulisan kecil.
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 24),
              child: Column(
                children: [
                  Image.asset('assets/images/rsia.png', height: 44),
                  const SizedBox(height: 8),
                  const Text('Portal Pasien RME \u2022 versi 3.0', style: TextStyle(color: WarnaRSIA.teksAbu, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
