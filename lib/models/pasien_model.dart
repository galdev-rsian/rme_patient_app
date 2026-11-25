// ============================================================
//  pasien_model.dart — "CETAKAN" (blueprint) data satu pasien.
//  Tujuannya: data mentah dari API (berupa JSON) diubah menjadi
//  objek Dart yang rapi, sehingga bisa dipanggil seperti:
//      pasien.nmPasien     pasien.noRkmMedis
//  tanpa risiko salah ketik nama key JSON di banyak tempat.
// ============================================================

class Pasien {
  // final = nilainya diisi SEKALI saat dibuat, lalu tidak bisa diganti (aman).
  final String noRkmMedis; // nomor rekam medis (wajib ada).
  final String nmPasien;   // nama lengkap pasien (wajib ada).

  // Tanda "?" (mis. String?) artinya boleh KOSONG / null.
  // Dipakai untuk data yang MUNGKIN tidak dikirim oleh server.
  final String? noKtp;
  final String? jk;        // jenis kelamin: 'L' = laki-laki, selain itu perempuan.
  final String? tglLahir;
  final String? alamat;
  final String? noTlp;
  final String? email;

  // Constructor dengan "named parameters" (parameter bernama, di dalam { }).
  // required = WAJIB diisi saat membuat Pasien baru.
  // this.noRkmMedis = langsung mengisi variabel class dengan parameter yang bernama sama.
  const Pasien({
    required this.noRkmMedis,
    required this.nmPasien,
    this.noKtp,
    this.jk,
    this.tglLahir,
    this.alamat,
    this.noTlp,
    this.email,
  });

  // factory = constructor khusus yang mengembalikan objek yang sudah jadi.
  // Pasien.fromJson(...) mengubah data JSON dari server menjadi objek Pasien.
  // Contoh JSON yang datang dari Laravel:
  //   {"no_rkm_medis": "123456", "nm_pasien": "Budi Santoso", "jk": "L", ...}
  factory Pasien.fromJson(Map<String, dynamic> json) {
    return Pasien(
      // json['no_rkm_medis'] = ambil nilai berdasarkan nama key JSON-nya.
      // Tanda "?? ''" artinya: kalau nilainya null, pakai string kosong,
      // supaya aplikasi tidak error saat server tidak mengirim data itu.
      noRkmMedis: json['no_rkm_medis'] ?? '',
      nmPasien: json['nm_pasien'] ?? '',
      // Yang di bawah ini tidak perlu "?? ''" karena tipenya sudah String? (boleh null).
      noKtp: json['no_ktp'],
      jk: json['jk'],
      tglLahir: json['tgl_lahir'],
      alamat: json['alamat'],
      noTlp: json['no_tlp'],
      email: json['email'],
    );
  }
}