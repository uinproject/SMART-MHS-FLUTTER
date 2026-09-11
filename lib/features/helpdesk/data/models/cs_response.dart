class CsResponse {
  final bool success;
  final String? message;
  final List<CsDetail>? data;

  CsResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory CsResponse.fromJson(Map<String, dynamic> json) {
    return CsResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: json['data'] != null && json['data'] is List
          ? (json['data'] as List).map((i) => CsDetail.fromJson(i)).toList()
          : null,
    );
  }
}

class CsDetail {
  final String nowa;
  final String namaadmin;
  final String linkimageprofil;
  final String namabagian;
  final String jamoperasional;
  final String layanan;
  final bool online;
  final String keteranganhari;

  CsDetail({
    required this.nowa,
    required this.namaadmin,
    required this.linkimageprofil,
    required this.namabagian,
    required this.jamoperasional,
    required this.layanan,
    required this.online,
    required this.keteranganhari,
  });

  factory CsDetail.fromJson(Map<String, dynamic> json) {
    return CsDetail(
      nowa: json['nowa']?.toString() ?? '',
      namaadmin: json['namaadmin']?.toString() ?? '',
      linkimageprofil: json['linkimageprofil']?.toString() ?? '',
      namabagian: json['namabagian']?.toString() ?? '',
      jamoperasional: json['jamoperasional']?.toString() ?? '',
      layanan: json['layanan']?.toString() ?? '',
      online: json['online'] == true ||
          json['online'] == 1 ||
          json['online'] == 'true',
      keteranganhari: json['keteranganhari']?.toString() ?? '',
    );
  }
}
