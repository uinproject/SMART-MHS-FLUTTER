class EdomSemestersResponse {
  final bool success;
  final String? message;
  final EdomPeriode? data;

  EdomSemestersResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory EdomSemestersResponse.fromJson(Map<String, dynamic> json) {
    return EdomSemestersResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? EdomPeriode.fromJson(json['data']) : null,
    );
  }
}

class EdomPeriode {
  final String thsmtPengisian;
  final List<EdomItemSemester> dataTahun;

  EdomPeriode({
    required this.thsmtPengisian,
    required this.dataTahun,
  });

  factory EdomPeriode.fromJson(Map<String, dynamic> json) {
    return EdomPeriode(
      thsmtPengisian: json['thsmt_pengisian']?.toString() ?? '',
      dataTahun: json['data_tahun'] != null
          ? List<EdomItemSemester>.from(
              json['data_tahun'].map((x) => EdomItemSemester.fromJson(x)))
          : [],
    );
  }
}

class EdomItemSemester {
  final String thsms;
  final String semester;
  int kodeStatusEval;
  String keteranganStatus;

  EdomItemSemester({
    required this.thsms,
    required this.semester,
    required this.kodeStatusEval,
    required this.keteranganStatus,
  });

  factory EdomItemSemester.fromJson(Map<String, dynamic> json) {
    return EdomItemSemester(
      thsms: json['thsms']?.toString() ?? '',
      semester: json['semester']?.toString() ?? '',
      kodeStatusEval: _toInt(json['kodestatuseval'] ?? json['kodeStatusEval']),
      keteranganStatus: (json['keteranganstatus'] ?? json['keteranganStatus'])?.toString() ?? '',
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
