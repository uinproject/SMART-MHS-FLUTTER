class JadwalResponse {
  final bool success;
  final String? message;
  final String semester;
  final List<Hari>? data;

  JadwalResponse({
    required this.success,
    this.message,
    required this.semester,
    this.data,
  });

  factory JadwalResponse.fromJson(Map<String, dynamic> json) {
    return JadwalResponse(
      success: json['success'] ?? false,
      message: json['message'],
      semester: json['semester']?.toString() ?? '',
      data: json['data'] != null
          ? List<Hari>.from(json['data'].map((x) => Hari.fromJson(x)))
          : null,
    );
  }
}

class Hari {
  final String hari;
  final List<MataKuliah> itemMakul;

  Hari({
    required this.hari,
    required this.itemMakul,
  });

  factory Hari.fromJson(Map<String, dynamic> json) {
    return Hari(
      hari: json['hari'] ?? '',
      itemMakul: json['item_makul'] != null
          ? List<MataKuliah>.from(
              json['item_makul'].map((x) => MataKuliah.fromJson(x)))
          : [],
    );
  }
}

class MataKuliah {
  final String makul;
  final int sks;
  final String ruang;
  final String waktu;
  final String dosen;
  final bool jamdiganti;
  final bool jampengganti;
  final String? tgldiganti;
  final String? tglpengganti;
  final String? pertemuandiganti;

  MataKuliah({
    required this.makul,
    required this.sks,
    required this.ruang,
    required this.waktu,
    required this.dosen,
    required this.jamdiganti,
    required this.jampengganti,
    this.tgldiganti,
    this.tglpengganti,
    this.pertemuandiganti,
  });

  factory MataKuliah.fromJson(Map<String, dynamic> json) {
    return MataKuliah(
      makul: json['makul'] ?? '',
      sks: _toInt(json['sks']),
      ruang: json['ruang'] ?? '',
      waktu: json['waktu'] ?? '',
      dosen: json['dosen'] ?? '',
      jamdiganti: json['jamdiganti'] == true || json['jamdiganti'] == 1,
      jampengganti: json['jampengganti'] == true || json['jampengganti'] == 1,
      tgldiganti: json['tgldiganti'],
      tglpengganti: json['tglpengganti'],
      pertemuandiganti: json['pertemuandiganti'],
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
