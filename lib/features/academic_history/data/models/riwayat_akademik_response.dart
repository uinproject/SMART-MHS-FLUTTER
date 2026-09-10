class RiwayatAkademikResponse {
  final bool success;
  final String message;
  final AcademicData? data;

  RiwayatAkademikResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory RiwayatAkademikResponse.fromJson(Map<String, dynamic> json) {
    return RiwayatAkademikResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AcademicData.fromJson(json['data']) : null,
    );
  }
}

class AcademicData {
  final List<IpkItem> riwayatIpk;
  final List<IpsItem> riwayatIps;
  final List<SksItem> riwayatSks;
  final List<RegistrasiItem> riwayatRegistrasi;

  AcademicData({
    required this.riwayatIpk,
    required this.riwayatIps,
    required this.riwayatSks,
    required this.riwayatRegistrasi,
  });

  factory AcademicData.fromJson(Map<String, dynamic> json) {
    return AcademicData(
      riwayatIpk: json['riwayat_ipk'] != null
          ? List<IpkItem>.from(json['riwayat_ipk'].map((x) => IpkItem.fromJson(x)))
          : [],
      riwayatIps: json['riwayat_ips'] != null
          ? List<IpsItem>.from(json['riwayat_ips'].map((x) => IpsItem.fromJson(x)))
          : [],
      riwayatSks: json['riwayat_sks'] != null
          ? List<SksItem>.from(json['riwayat_sks'].map((x) => SksItem.fromJson(x)))
          : [],
      riwayatRegistrasi: json['riwayat_trregistrasi'] != null
          ? List<RegistrasiItem>.from(json['riwayat_trregistrasi'].map((x) => RegistrasiItem.fromJson(x)))
          : [],
    );
  }
}

class IpkItem {
  final int semester;
  final String thsmt;
  final double ipk;

  IpkItem({
    required this.semester,
    required this.thsmt,
    required this.ipk,
  });

  factory IpkItem.fromJson(Map<String, dynamic> json) {
    return IpkItem(
      semester: _toInt(json['semester']),
      thsmt: json['thsmt']?.toString() ?? '',
      ipk: _toDouble(json['ipk']),
    );
  }
}

class IpsItem {
  final int semester;
  final String thsmt;
  final double ips;

  IpsItem({
    required this.semester,
    required this.thsmt,
    required this.ips,
  });

  factory IpsItem.fromJson(Map<String, dynamic> json) {
    return IpsItem(
      semester: _toInt(json['semester']),
      thsmt: json['thsmt']?.toString() ?? '',
      ips: _toDouble(json['ips']),
    );
  }
}

class SksItem {
  final int semester;
  final String thsmt;
  final int sks;

  SksItem({
    required this.semester,
    required this.thsmt,
    required this.sks,
  });

  factory SksItem.fromJson(Map<String, dynamic> json) {
    return SksItem(
      semester: _toInt(json['semester']),
      thsmt: json['thsmt']?.toString() ?? '',
      sks: _toInt(json['sks']),
    );
  }
}

class RegistrasiItem {
  final int semester;
  final String thsmt;
  final String status;
  final String kodeStatus;

  RegistrasiItem({
    required this.semester,
    required this.thsmt,
    required this.status,
    required this.kodeStatus,
  });

  factory RegistrasiItem.fromJson(Map<String, dynamic> json) {
    return RegistrasiItem(
      semester: _toInt(json['semester']),
      thsmt: json['thsmt']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      kodeStatus: json['kode_status']?.toString() ?? '',
    );
  }
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
