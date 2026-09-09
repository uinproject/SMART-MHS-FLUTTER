class EdomCoursesResponse {
  final bool success;
  final String? message;
  final List<EdomMakulEval>? data;

  EdomCoursesResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory EdomCoursesResponse.fromJson(Map<String, dynamic> json) {
    return EdomCoursesResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null
          ? List<EdomMakulEval>.from(
              json['data'].map((x) => EdomMakulEval.fromJson(x)))
          : null,
    );
  }
}

class EdomMakulEval {
  final String ideval;
  final String namamkeval;
  final String kdmkeval;
  final String kelasmkeval;
  final String doseneval;
  final String urlfotodoseneval;
  double rating;
  String komentar;
  String statusEval;

  EdomMakulEval({
    required this.ideval,
    required this.namamkeval,
    required this.kdmkeval,
    required this.kelasmkeval,
    required this.doseneval,
    required this.urlfotodoseneval,
    required this.rating,
    required this.komentar,
    required this.statusEval,
  });

  factory EdomMakulEval.fromJson(Map<String, dynamic> json) {
    return EdomMakulEval(
      ideval: json['ideval']?.toString() ?? '',
      namamkeval: json['namamkeval']?.toString() ?? '',
      kdmkeval: json['kdmkeval']?.toString() ?? '',
      kelasmkeval: json['kelasmkeval']?.toString() ?? '',
      doseneval: json['doseneval']?.toString() ?? '',
      urlfotodoseneval: json['urlfotodoseneval']?.toString() ?? '',
      rating: _toDouble(json['rating']),
      komentar: json['komentar']?.toString() ?? '',
      statusEval: (json['statuseval'] ?? json['statusEval'])?.toString() ?? '0',
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
