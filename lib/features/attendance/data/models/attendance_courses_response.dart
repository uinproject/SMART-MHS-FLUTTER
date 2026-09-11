class AttendanceCoursesResponse {
  final bool success;
  final String? message;
  final List<AttendanceCourseItem> data;

  AttendanceCoursesResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory AttendanceCoursesResponse.fromJson(Map<String, dynamic> json) {
    var rawList = json['data'];
    List<AttendanceCourseItem> items = [];
    if (rawList is List) {
      items = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => AttendanceCourseItem.fromJson(e))
          .toList();
    }

    return AttendanceCoursesResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: items,
    );
  }
}

class AttendanceCourseItem {
  final String makul;
  final String kdMakul;
  final int sks;
  final String dosen;
  final String urlFotoDosen;
  final String hari;
  final String jam;
  final int tahunSmt;
  final int semester;
  final String kdJen;
  final String kdPst;
  final String kelas;
  final String idAbsensi;
  final String ruang;
  final String presentase;
  final int jumlahPertemuan;
  final int jumlahKehadiran;

  AttendanceCourseItem({
    required this.makul,
    required this.kdMakul,
    required this.sks,
    required this.dosen,
    required this.urlFotoDosen,
    required this.hari,
    required this.jam,
    required this.tahunSmt,
    required this.semester,
    required this.kdJen,
    required this.kdPst,
    required this.kelas,
    required this.idAbsensi,
    required this.ruang,
    required this.presentase,
    required this.jumlahPertemuan,
    required this.jumlahKehadiran,
  });

  factory AttendanceCourseItem.fromJson(Map<String, dynamic> json) {
    return AttendanceCourseItem(
      makul: json['makul']?.toString() ?? '',
      kdMakul: json['kd_makul']?.toString() ?? '',
      sks: int.tryParse(json['sks']?.toString() ?? '') ?? 0,
      dosen: json['dosen']?.toString() ?? '',
      urlFotoDosen: json['urlfotodosen']?.toString() ?? '',
      hari: json['hari']?.toString() ?? '',
      jam: json['jam']?.toString() ?? '',
      tahunSmt: int.tryParse(json['tahun_smt']?.toString() ?? '') ?? 0,
      semester: int.tryParse(json['semester']?.toString() ?? '') ?? 0,
      kdJen: json['kd_jen']?.toString() ?? '',
      kdPst: json['kd_pst']?.toString() ?? '',
      kelas: json['kelas']?.toString() ?? '',
      idAbsensi: json['id_absensi']?.toString() ?? '',
      ruang: json['ruang']?.toString() ?? '',
      presentase: json['presentase']?.toString() ?? '0',
      jumlahPertemuan: int.tryParse(json['jumlahpertemuan']?.toString() ?? '') ?? 0,
      jumlahKehadiran: int.tryParse(json['jumlahkehadiran']?.toString() ?? '') ?? 0,
    );
  }
}
