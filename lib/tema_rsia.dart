// ============================================================
//  tema_rsia.dart — PUSAT WARNA & GAYA RSIA (BARU di versi 2).
//  Semua halaman mengambil warna dari FILE INI, jadi kalau suatu
//  saat RS ingin mengubah warna aplikasi, cukup ubah di sini
//  dan seluruh aplikasi ikut berubah (prinsip "satu sumber").
//  Warna diambil langsung dari logo RSIA:
//    hijau  = tulisan "RSIAAN"       biru = lingkaran dalam logo
//    emas   = sinar matahari         merah = bulan sabit (aksen)
// ============================================================

// Tetap wajib import material karena di sini dipakai tipe Color
// dan LinearGradient yang berasal dari Flutter.
import 'package:flutter/material.dart';

// Class pembungkus konstanta warna. "static const" artinya:
// nilainya tetap sejak awal dan dipanggil TANPA membuat objek,
// contoh pemakaian: WarnaRSIA.hijau
class WarnaRSIA {
  // Hijau utama RSIA — warna teks "RSIAAN" pada logo.
  static const hijau = Color(0xFF00A651);
  // Hijau lebih gelap — untuk gradien, teks judul, dan hover tombol.
  static const hijauTua = Color(0xFF007A3D);
  // Biru laut — warna lingkaran dalam logo RSIA.
  static const biru = Color(0xFF1E5A96);
  // Biru lebih gelap — pasangan gradien.
  static const biruTua = Color(0xFF153F6E);
  // Emas — warna sinar matahari pada logo (untuk banner promosi).
  static const emas = Color(0xFFF2B705);
  // Merah — aksen dari bulan sabit logo; dipakai HEMAT (status error).
  static const merah = Color(0xFFDC2626);
  // Warna netral: latar halaman, teks, dan garis pemisah.
  static const latar = Color(0xFFF4F7F6);    // latar abu sangat muda kehijauan
  static const teksGelap = Color(0xFF1F2937); // teks utama (hampir hitam)
  static const teksAbu = Color(0xFF6B7280);   // teks sekunder / keterangan
  static const garis = Color(0xFFE5E9EC);     // bingkai kartu & kotak input
}

// Gradien RESMI RSIA (hijau → biru) untuk header, kartu sambutan,
// dan banner promosi. Karena bernama "const", gradien ini dibuat
// sekali saja lalu dipakai berulang (hemat memori).
// Cara pakai: decoration: BoxDecoration(gradient: gradasiRSIA)
const LinearGradient gradasiRSIA = LinearGradient(
  colors: [Color(0xFF00A651), Color(0xFF1E5A96)],
  begin: Alignment.topLeft,     // arah mulai gradien (kiri atas)
  end: Alignment.bottomRight,   // arah selesai (kanan bawah)
);

// Gradien emas untuk banner promosi khusus (penawaran/paket).
const LinearGradient gradasiEmas = LinearGradient(
  colors: [Color(0xFFF2B705), Color(0xFFE8930C)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);