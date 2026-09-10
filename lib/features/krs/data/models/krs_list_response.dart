// Models for the "Input KRS" endpoints.
// Mirrors the legacy Kotlin models `KrsMKgetResponse` and `KrsMKpostResponse`
// (plain JSON responses — no decryption, exact same serialized names).
//
// GET krsservices/list_krs_mk  -> KrsListResponse
// POST krsservices/input_krs_mata_kuliah -> KrsPostResponse (data = latest list)

/// GET krsservices/list_krs_mk
class KrsListResponse {
  final bool success;
  final String? message;
  final String? waktuMulai;
  final String? waktuSelesai;

  /// Server-side EDOM gate (same pattern as `PenawaranMKgetResponse` /
  /// `KhsResponse`): `false` = student must complete the lecturer
  /// evaluation (EDOM) before entering KRS. Defaults to `true` when the
  /// server omits it.
  final bool cekEval;
  final List<KrsMataKuliah>? data;

  KrsListResponse({
    required this.success,
    this.message,
    this.waktuMulai,
    this.waktuSelesai,
    this.cekEval = true,
    this.data,
  });

  factory KrsListResponse.fromJson(Map<String, dynamic> json) {
    return KrsListResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString(),
      waktuMulai: json['waktu_mulai']?.toString(),
      waktuSelesai: json['waktu_selesai']?.toString(),
      cekEval: json['cekeval'] == null ? true : json['cekeval'] == true,
      data: json['data'] != null
          ? List<KrsMataKuliah>.from(
              json['data'].map((x) => KrsMataKuliah.fromJson(x)),
            )
          : null,
    );
  }
}

/// POST krsservices/input_krs_mata_kuliah.
/// `data` holds the fresh list after submit (legacy re-binds the adapter
/// from it); nullable because the legacy model marks it nullable in
/// practice (`data_krsmk != null` check before re-bind).
class KrsPostResponse {
  final bool success;
  final String message;

  /// "xxx" fallback in legacy when the field is missing.
  final String tglInput;
  final List<KrsMataKuliah>? data;

  KrsPostResponse({
    required this.success,
    required this.message,
    required this.tglInput,
    this.data,
  });

  factory KrsPostResponse.fromJson(Map<String, dynamic> json) {
    return KrsPostResponse(
      success: json['success'] ?? false,
      message: json['message']?.toString() ?? '',
      tglInput: json['tgl_input']?.toString() ?? 'xxx',
      data: json['data'] != null
          ? List<KrsMataKuliah>.from(
              json['data'].map((x) => KrsMataKuliah.fromJson(x)),
            )
          : null,
    );
  }
}

class KrsMataKuliah {
  final String kodeMk;
  final String makul;
  final int sksMk;
  final int semesterMk;
  final List<KrsJadwal> itemJadwal;

  KrsMataKuliah({
    required this.kodeMk,
    required this.makul,
    required this.sksMk,
    required this.semesterMk,
    required this.itemJadwal,
  });

  factory KrsMataKuliah.fromJson(Map<String, dynamic> json) {
    return KrsMataKuliah(
      kodeMk: json['kode_mk']?.toString() ?? '',
      makul: json['makul']?.toString() ?? '',
      sksMk: _toInt(json['sks_mk']) ?? 0,
      semesterMk: _toInt(json['semester_mk']) ?? 0,
      itemJadwal: json['item_jadwal'] != null
          ? List<KrsJadwal>.from(
              json['item_jadwal'].map((x) => KrsJadwal.fromJson(x)),
            )
          : [],
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class KrsJadwal {
  final String kodeMk;
  final String makul;
  final String dosen;
  final String? nodos;
  final String waktu;
  final int kuota;

  /// Mutated after a successful submit when the response carries the fresh
  /// list (the caller replaces the whole list instead, so this stays
  /// immutable here).
  final int jmlhPeserta;

  /// "Y" | "T" — server-side state: this schedule is already taken by the
  /// student (auto-checked on load).
  final String selected;

  /// "Y" when this exact schedule row was saved by the student.
  final String issaved;

  /// "Y" when already approved by the guardian lecturer (row locked).
  final String isacc;
  final int sksMk;

  /// e.g. "Senin" — empty when not scheduled.
  final String jadwalHari;

  /// e.g. "07.30-09.10" or "07,30-09,10" — empty when not scheduled.
  final String jadwalJam;
  final String jadwalKelas;
  final String jadwalRuang;

  KrsJadwal({
    required this.kodeMk,
    required this.makul,
    required this.dosen,
    this.nodos,
    required this.waktu,
    required this.kuota,
    required this.jmlhPeserta,
    required this.selected,
    required this.issaved,
    required this.isacc,
    required this.sksMk,
    required this.jadwalHari,
    required this.jadwalJam,
    required this.jadwalKelas,
    required this.jadwalRuang,
  });

  factory KrsJadwal.fromJson(Map<String, dynamic> json) {
    return KrsJadwal(
      kodeMk: json['kode_mk']?.toString() ?? '',
      makul: json['makul']?.toString() ?? '',
      dosen: json['dosen']?.toString() ?? '',
      nodos: json['nodos']?.toString(),
      waktu: json['waktu']?.toString() ?? '',
      kuota: _toInt(json['kuota']) ?? 0,
      jmlhPeserta: _toInt(json['jmlh_peserta']) ?? 0,
      selected: json['selected']?.toString() ?? 'T',
      issaved: json['issaved']?.toString() ?? 'T',
      isacc: json['isacc']?.toString() ?? 'T',
      sksMk: _toInt(json['sks_mk']) ?? 0,
      jadwalHari: json['jadwal_hari']?.toString() ?? '',
      jadwalJam: json['jadwal_jam']?.toString() ?? '',
      jadwalKelas: json['jadwal_kelas']?.toString() ?? '',
      jadwalRuang: json['jadwal_ruang']?.toString() ?? '',
    );
  }

  /// Row disabled when full (and not the student's own saved row) or already
  /// approved by the guardian lecturer — port of the legacy adapter rule.
  bool get disabled => (jmlhPeserta >= kuota && issaved == 'T') || isacc == 'Y';

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
