// Model for the "Lihat KRS" endpoint.
// Mirrors the legacy Kotlin model `KRSMKMhs` (plain JSON response — no
// decryption, exact same serialized names).
//
// GET krsservices/krs -> { success, message, jatah_sks, semester_berjalan,
//                          data: [itemmakul...] }

/// GET krsservices/krs
class KrsResponse {
  final bool success;
  final String? message;
  final int? jatahSks;
  final String? semesterBerjalan;
  final List<KrsItemMakul>? data;

  KrsResponse({
    required this.success,
    this.message,
    this.jatahSks,
    this.semesterBerjalan,
    this.data,
  });

  factory KrsResponse.fromJson(Map<String, dynamic> json) {
    return KrsResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString(),
      jatahSks: _toInt(json['jatah_sks']),
      semesterBerjalan: json['semester_berjalan']?.toString(),
      data: json['data'] != null
          ? List<KrsItemMakul>.from(
              json['data'].map((x) => KrsItemMakul.fromJson(x)))
          : null,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class KrsItemMakul {
  final String kodeMk;
  final int paketSemester;
  final String kelas;
  final String makul;

  /// ⚠️ STRING in the legacy response (`sks: String` in `KRSMKMhs.kt`);
  /// parsed to int only when summing credits (legacy `sks.toInt()`).
  final String sks;
  final String ruang;
  final String waktu;
  final String dosen;

  KrsItemMakul({
    required this.kodeMk,
    required this.paketSemester,
    required this.kelas,
    required this.makul,
    required this.sks,
    required this.ruang,
    required this.waktu,
    required this.dosen,
  });

  factory KrsItemMakul.fromJson(Map<String, dynamic> json) {
    return KrsItemMakul(
      kodeMk: json['kode_mk']?.toString() ?? '',
      paketSemester: _toInt(json['paket_semester']) ?? 0,
      kelas: json['kelas']?.toString() ?? '',
      makul: json['makul']?.toString() ?? '',
      sks: json['sks']?.toString() ?? '0',
      ruang: json['ruang']?.toString() ?? '',
      waktu: json['waktu']?.toString() ?? '',
      dosen: json['dosen']?.toString() ?? '',
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
