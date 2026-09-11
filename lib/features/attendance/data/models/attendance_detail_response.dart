class AttendanceDetailResponse {
  final bool success;
  final String? message;
  final AttendanceMeetingDetail? data;

  AttendanceDetailResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory AttendanceDetailResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceDetailResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? AttendanceMeetingDetail.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AttendanceMeetingDetail {
  final String idAbsensi;
  final String mataKuliah;
  final String waktu;
  final int pertemuanKe;
  final String ketHadir;
  final String dosen;
  final String judul;
  final String isi;
  final List<AttendanceMaterialItem> materiFile;

  AttendanceMeetingDetail({
    required this.idAbsensi,
    required this.mataKuliah,
    required this.waktu,
    required this.pertemuanKe,
    required this.ketHadir,
    required this.dosen,
    required this.judul,
    required this.isi,
    required this.materiFile,
  });

  bool get isPresent => ketHadir.trim().toUpperCase() == 'Y';

  factory AttendanceMeetingDetail.fromJson(Map<String, dynamic> json) {
    var rawMateri = json['materi_file'];
    List<AttendanceMaterialItem> materiList = [];
    if (rawMateri is List) {
      materiList = rawMateri
          .whereType<Map<String, dynamic>>()
          .map((e) => AttendanceMaterialItem.fromJson(e))
          .toList();
    }

    return AttendanceMeetingDetail(
      idAbsensi: json['idabsensi']?.toString() ?? '',
      mataKuliah: json['mata_kuliah']?.toString() ?? '',
      waktu: json['waktu']?.toString() ?? '',
      pertemuanKe: int.tryParse(json['pertemuanke']?.toString() ?? '') ?? 0,
      ketHadir: json['ket_hadir']?.toString() ?? '',
      dosen: json['dosen']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      isi: json['isi']?.toString() ?? '',
      materiFile: materiList,
    );
  }
}

class AttendanceMaterialItem {
  final String judul;
  final String namaFile;
  final String link;

  AttendanceMaterialItem({
    required this.judul,
    required this.namaFile,
    required this.link,
  });

  factory AttendanceMaterialItem.fromJson(Map<String, dynamic> json) {
    return AttendanceMaterialItem(
      judul: json['judul']?.toString() ?? '',
      namaFile: json['nama_file']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
    );
  }
}
