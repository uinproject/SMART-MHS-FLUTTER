class PresenceVerificationResponse {
  final bool success;
  final String message;
  final PresenceDetailData? data;

  PresenceVerificationResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory PresenceVerificationResponse.fromJson(Map<String, dynamic> json) {
    return PresenceVerificationResponse(
      success: json['success'] == true || json['success'] == 1 || json['success'] == 'true',
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? PresenceDetailData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class PresenceDetailData {
  final bool verloc;
  final bool statusabsen;
  final String mataKuliah;
  final int semester;
  final String idabsensi;
  final String kodeMakul;
  final String judulKuliah;
  final String isiKuliah;
  final String ruang;
  final String pertemuanKe;
  final String dosen;
  final String jam;
  final String selesaiPada;
  final String? namaLokasi;

  PresenceDetailData({
    required this.verloc,
    required this.statusabsen,
    required this.mataKuliah,
    required this.semester,
    required this.idabsensi,
    required this.kodeMakul,
    required this.judulKuliah,
    required this.isiKuliah,
    required this.ruang,
    required this.pertemuanKe,
    required this.dosen,
    required this.jam,
    required this.selesaiPada,
    this.namaLokasi,
  });

  factory PresenceDetailData.fromJson(Map<String, dynamic> json) {
    return PresenceDetailData(
      verloc: json['verloc'] == true || json['verloc'] == 1 || json['verloc'] == 'true',
      statusabsen: json['statusabsen'] == true || json['statusabsen'] == 1 || json['statusabsen'] == 'true',
      mataKuliah: json['mata_kuliah']?.toString() ?? '',
      semester: int.tryParse(json['semester']?.toString() ?? '0') ?? 0,
      idabsensi: json['idabsensi']?.toString() ?? '',
      kodeMakul: json['kode_makul']?.toString() ?? '',
      judulKuliah: json['judul_kuliah']?.toString() ?? '',
      isiKuliah: json['isi_kuliah']?.toString() ?? '',
      ruang: json['ruang']?.toString() ?? '',
      pertemuanKe: json['pertemuan_ke']?.toString() ?? '',
      dosen: json['dosen']?.toString() ?? '',
      jam: json['jam']?.toString() ?? '',
      selesaiPada: json['selesai_pada']?.toString() ?? '',
      namaLokasi: json['nama_lokasi']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verloc': verloc,
      'statusabsen': statusabsen,
      'mata_kuliah': mataKuliah,
      'semester': semester,
      'idabsensi': idabsensi,
      'kode_makul': kodeMakul,
      'judul_kuliah': judulKuliah,
      'isi_kuliah': isiKuliah,
      'ruang': ruang,
      'pertemuan_ke': pertemuanKe,
      'dosen': dosen,
      'jam': jam,
      'selesai_pada': selesaiPada,
      'nama_lokasi': namaLokasi,
    };
  }
}
