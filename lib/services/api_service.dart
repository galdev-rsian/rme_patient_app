// ============================================================
//  api_service.dart — "JEMBATAN" antara aplikasi Flutter dan
//  server Laravel. SEMUA permintaan data (GET) dan pengiriman
//  data (POST) ke server dikerjakan lewat file ini supaya:
//
//  1) Alamat API & cara membawa token diatur DI SATU tempat saja.
//  2) Halaman-halaman menu cukup memanggil:
//        ApiService.get('/lab')                ← daftar hasil lab
//        ApiService.post('/pendaftaran', {...}) ← kirim pendaftaran
//
//  PETA ENDPOINT — pasangan Flutter ↔ Laravel (WAJIB SAMA!):
//  ------------------------------------------------------------------
//  Halaman di app                Panggilan di Flutter         Method di routes/api.php
//  ------------------------------------------------------------------
//  login_page.dart               post('/login')               PasienAuthController@login
//  change_password_page.dart     post('/change-password')     PasienAuthController@changePassword
//  dashboard_page.dart (logout)  post('/logout')              PasienAuthController@logout
//  profil_page.dart              get('/me')                   PasienAuthController@me
//  pendaftaran_page.dart         get('/poli/daftar-poli')     PasienPendaftaranController@daftarPoli
//  pendaftaran_page.dart         get('/poli/jadwal')          PasienPendaftaranController@jadwal
//  pendaftaran_page.dart         post('/pendaftaran')         PasienPendaftaranController@store
//  riwayat_periksa_page.dart     get('/kunjungan')            PasienPendaftaranController@riwayatKunjungan
//  jadwal_kontrol_page.dart      get('/kunjungan')            (difilter tanggal >= hari ini)
//  hasil_lab_page.dart           get('/lab')                  PasienLabController@index
//  hasil_lab_page.dart           get('/lab/$noOrder')         PasienLabController@detail
//  resep_aktif_page.dart         get('/resep')                PasienResepController@index
//  tagihan_page.dart             get('/tagihan')              PasienTagihanController@index
//  notifikasi_page.dart          get('/notifikasi')           PasienNotifikasiController@index
//  notifikasi_page.dart          post('/notifikasi/$id/baca') PasienNotifikasiController@tandaiBaca
//  edukasi_page.dart             get('/edukasi')              PasienEdukasiController@index
//  edukasi_page.dart             get('/edukasi/$id')          PasienEdukasiController@detail
//  ------------------------------------------------------------------
//  Perhatikan: bagian "/api/pasien" TIDAK ditulis di sini — itu sudah
//  termasuk AppConfig.apiBaseUrl (config.dart). Halaman hanya menulis
//  "sisa" alamatnya, contoh: /pasien/lab → cukup '/lab'.
//
//  PRINSIP ARSITEKTUR (penting!):
//  Aplikasi ini HANYA FRONTEND PASIEN. Artinya aplikasi hanya:
//    • MEMBACA data milik pasien yang sedang login
//      (hasil lab, tagihan, riwayat, resep, dsb.)
//    • MENGIRIM aksi milik pasien sendiri
//      (login, ganti password, pendaftaran online)
//  Data medis TIDAK PERNAH dibuat dari aplikasi ini — itu tugas staf
//  lewat aplikasi web RME yang sudah ada di sisi RS.
// ============================================================

// dart:convert = jsonDecode: mengubah teks JSON dari server menjadi
// Map/List Dart yang bisa dibaca.
import 'dart:convert';
// package:http = pengirim permintaan HTTP (sudah ada di pubspec.yaml).
import 'package:http/http.dart' as http;
// package:shared_preferences = penyimpanan kecil di HP tempat token
// disimpan sejak login (lihat login_page.dart).
import 'package:shared_preferences/shared_preferences.dart';
// Alamat API diambil dari file config.dart di folder yang sama.
import 'config.dart';

// ApiService = kumpulan FUNGSI STATIS (dipakai tanpa membuat objek).
// Dari halaman mana pun cukup tulis: ApiService.get('/lab')
class ApiService {
  // Batas waktu menunggu jawaban server: 15 detik. Kalau lebih,
  // dianggap gagal (server mati / koneksi buruk) → muncul pesan jelas.
  static const Duration _batasWaktu = Duration(seconds: 15);

  // ---- Ambil token yang tersimpan sejak login ----
  // Token = "kartu identitas pasien" yang dikirim di setiap permintaan
  // agar server tahu SIAPA yang sedang bertanya.
  static Future<String?> _ambilToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('auth_token');
  }

  // ---- Susun HEADER standar untuk setiap permintaan ----
  // Header = "kartu nama" yang menyertai paket permintaan:
  //  • Accept: jawaban yang kami harap berupa JSON
  //  • Content-Type: isi yang kami kirim berupa JSON
  //  • Authorization: Bearer <token> = kartu identitas pasien
  static Future<Map<String, String>> _headers({bool butuhToken = true}) async {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (butuhToken) {
      final token = await _ambilToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ============================================================
  //  GET — MEMINTA data dari server.
  //  Contoh pemakaian di halaman menu (lihat hasil_lab_page.dart):
  //      final hasil = await ApiService.get('/lab');
  //  Nilai kembalian = hasil jsonDecode dari jawaban Laravel.
  //  Format jawaban backend selalu: {"status": true, "message": "...",
  //  "data": [ {...}, {...} ]} — kecuali login (ada token & pasien).
  // ============================================================
  static Future<dynamic> get(String endpoint) async {
    http.Response response;
    try {
      response = await http
          .get(
        // '${AppConfig.apiBaseUrl}$endpoint' = alamat lengkap,
        // contoh: http://192.168.0.104:8000/api/pasien + /lab
        Uri.parse('${AppConfig.apiBaseUrl}$endpoint'),
        headers: await _headers(),
      )
          .timeout(_batasWaktu);
    } catch (e) {
      // Masuk sini BUKAN karena server menolak, tapi karena permintaan
      // tidak sampai: server mati, WiFi putus, alamat salah, atau
      // waktu tunggu 15 detik terlampaui.
      throw Exception('Tidak dapat terhubung ke server. '
          'Cek koneksi internet & alamat API di lib/services/config.dart.');
    }
    // 200 = kode HTTP "sukses".
    if (response.statusCode == 200) return jsonDecode(response.body);
    // Selain 200 → ubah jawaban server menjadi pesan yang mudah dibaca.
    _lemparError(response);
  }

  // ============================================================
  //  POST — MENGIRIM data ke server (login, daftar online, dsb).
  //  Parameter butuhToken=false hanya dipakai untuk LOGIN, karena
  //  saat login kita memang BELUM punya token.
  //  Contoh:
  //      await ApiService.post('/pendaftaran',
  //        {'kd_poli': 'P001', 'kd_dokter': 'D001', 'tgl_periksa': '2026-01-15'},
  //        butuhToken: true);
  // ============================================================
  static Future<dynamic> post(
      String endpoint,
      Map<String, dynamic> body, {
        bool butuhToken = true,
      }) async {
    http.Response response;
    try {
      response = await http
          .post(
        Uri.parse('${AppConfig.apiBaseUrl}$endpoint'),
        headers: await _headers(butuhToken: butuhToken),
        // jsonEncode: Map Dart -> teks JSON untuk dikirim ke Laravel.
        body: jsonEncode(body),
      )
          .timeout(_batasWaktu);
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server. '
          'Cek koneksi internet & alamat API di lib/services/config.dart.');
    }
    // 200 (sukses) atau 201 (sukses & data baru dibuat, mis. pendaftaran).
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    _lemparError(response);
  }

  // ---- Ubah jawaban error dari server menjadi Exception berbahasa manusia ----
  // Tipe "Never" artinya: fungsi ini PASTI melempar error (tidak pernah
  // selesai dengan normal). Dengan begitu Dart tahu baris setelah
  // pemanggilannya tidak akan pernah dijalankan.
  static Never _lemparError(http.Response response) {
    // 401 Unauthorized = token salah/kadaluarsa → sesi berakhir.
    if (response.statusCode == 401) {
      throw Exception('Sesi berakhir. Silakan keluar dari aplikasi '
          'lalu login kembali.');
    }
    // Backend kita selalu mengirim {"status": false, "message": "alasan"}
    // saat menolak (mis. kuota penuh, password salah). Baca pesannya:
    String pesan = 'Terjadi kesalahan di server (kode ${response.statusCode}).';
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['message'] != null) {
        pesan = data['message'].toString();
      }
    } catch (_) {
      // Jawaban bukan JSON → diam saja, pakai pesan bawaan di atas.
    }
    throw Exception(pesan);
  }

  // ============================================================
  //  LOGOUT — dua langkah:
  //  1) Beri tahu server: "matikan token saya" (POST /logout — token
  //     dihapus dari tabel personal_access_tokens, jadi tidak bisa
  //     disalahpakai kalau dicuri).
  //  2) Hapus semua data login dari penyimpanan HP.
  //  Dipakai oleh tombol "Keluar" di dashboard_page.dart.
  // ============================================================
  static Future<void> logout() async {
    try {
      await post('/logout', {}); // server menghapus token di tabelnya.
    } catch (_) {
      // Walau server gagal dihubungi (mis. mati), tetap lanjut
      // menghapus data lokal — user tetap bisa keluar dari aplikasi.
    }
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
  }
}