class AttendanceListResponse {
  final bool success;
  final String? message;
  final List<AttendanceHistoryItem> data;

  AttendanceListResponse({
    required this.success,
    this.message,
    required this.data,
  });

  factory AttendanceListResponse.fromJson(Map<String, dynamic> json) {
    var rawList = json['data'];
    List<AttendanceHistoryItem> items = [];
    if (rawList is List) {
      items = rawList
          .whereType<Map<String, dynamic>>()
          .map((e) => AttendanceHistoryItem.fromJson(e))
          .toList();
    }

    return AttendanceListResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: items,
    );
  }
}

class AttendanceHistoryItem {
  final String idAbsensi;
  final String judul;
  final String isi;
  final int pertemuanKe;
  final String ketHadir;
  final int semester;
  final String kodeMakul;

  AttendanceHistoryItem({
    required this.idAbsensi,
    required this.judul,
    required this.isi,
    required this.pertemuanKe,
    required this.ketHadir,
    required this.semester,
    required this.kodeMakul,
  });

  bool get isPresent => ketHadir.trim().toUpperCase() == 'Y';

  factory AttendanceHistoryItem.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryItem(
      idAbsensi: json['idabsensi']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      isi: json['isi']?.toString() ?? '',
      pertemuanKe: int.tryParse(json['pertemuan_ke']?.toString() ?? '') ?? 0,
      ketHadir: json['ket_hadir']?.toString() ?? '',
      semester: int.tryParse(json['semester']?.toString() ?? '') ?? 0,
      kodeMakul: json['kode_makul']?.toString() ?? '',
    );
  }
}
