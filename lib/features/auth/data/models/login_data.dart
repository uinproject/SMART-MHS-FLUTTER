class LoginData {
  final String? nim;
  final String? kodeFakultas;
  final String? kodePst;
  final String? kodeJen;
  final String? nama;
  final String? fakultas;
  final String? programStudi;
  final int? semester;
  final String? ipkKumulatif;
  final int? sksTempuh;
  final int? angkatan;
  final String? jenjang;
  final String? telp;
  final String? status;
  final bool isAddEmail;
  final bool emailVerification;
  final String? email;
  final String? jenisKelamin;
  final String? batasSubscribe;
  final String? modeSubscribe;
  final String? midtransMerchantUrl;
  final String? midtransClientKey;
  final String? minAngkatanSubs;
  final List<String>? lockFitur;

  LoginData({
    this.nim,
    this.kodeFakultas,
    this.kodePst,
    this.kodeJen,
    this.nama,
    this.fakultas,
    this.programStudi,
    this.semester,
    this.ipkKumulatif,
    this.sksTempuh,
    this.angkatan,
    this.jenjang,
    this.telp,
    this.status,
    this.isAddEmail = false,
    this.emailVerification = false,
    this.email,
    this.jenisKelamin,
    this.batasSubscribe,
    this.modeSubscribe,
    this.midtransMerchantUrl,
    this.midtransClientKey,
    this.minAngkatanSubs,
    this.lockFitur,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      nim: json['nim'],
      kodeFakultas: json['kodefakultas'],
      kodePst: json['kodepst'],
      kodeJen: json['kodejen'],
      nama: json['nama'],
      fakultas: json['fakultas'],
      programStudi: json['programstudi'],
      semester: json['semester'],
      ipkKumulatif: json['ipkkumulatif'],
      sksTempuh: json['skstempuh'],
      angkatan: json['angkatan'],
      jenjang: json['jenjang'],
      telp: json['telp'],
      status: json['status'],
      isAddEmail: json['isaddemail'] ?? false,
      emailVerification: json['emailverifycation'] ?? false,
      email: json['email'],
      jenisKelamin: json['jeniskelamin'],
      batasSubscribe: json['batassubscribe'],
      modeSubscribe: json['modesubscribe'],
      midtransMerchantUrl: json['midtransmerchanturl'],
      midtransClientKey: json['midtransclientkey'],
      minAngkatanSubs: json['minangkatansubs'],
      lockFitur: json['lockfitur'] != null ? List<String>.from(json['lockfitur']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nim': nim,
      'kodefakultas': kodeFakultas,
      'kodepst': kodePst,
      'kodejen': kodeJen,
      'nama': nama,
      'fakultas': fakultas,
      'programstudi': programStudi,
      'semester': semester,
      'ipkkumulatif': ipkKumulatif,
      'skstempuh': sksTempuh,
      'angkatan': angkatan,
      'jenjang': jenjang,
      'telp': telp,
      'status': status,
      'isaddemail': isAddEmail,
      'emailverifycation': emailVerification,
      'email': email,
      'jeniskelamin': jenisKelamin,
      'batassubscribe': batasSubscribe,
      'modesubscribe': modeSubscribe,
      'midtransmerchanturl': midtransMerchantUrl,
      'midtransclientkey': midtransClientKey,
      'minangkatansubs': minAngkatanSubs,
      'lockfitur': lockFitur,
    };
  }

  LoginData copyWith({
    String? nim,
    String? kodeFakultas,
    String? kodePst,
    String? kodeJen,
    String? nama,
    String? fakultas,
    String? programStudi,
    int? semester,
    String? ipkKumulatif,
    int? sksTempuh,
    int? angkatan,
    String? jenjang,
    String? telp,
    String? status,
    bool? isAddEmail,
    bool? emailVerification,
    String? email,
    String? jenisKelamin,
    String? batasSubscribe,
    String? modeSubscribe,
    String? midtransMerchantUrl,
    String? midtransClientKey,
    String? minAngkatanSubs,
    List<String>? lockFitur,
  }) {
    return LoginData(
      nim: nim ?? this.nim,
      kodeFakultas: kodeFakultas ?? this.kodeFakultas,
      kodePst: kodePst ?? this.kodePst,
      kodeJen: kodeJen ?? this.kodeJen,
      nama: nama ?? this.nama,
      fakultas: fakultas ?? this.fakultas,
      programStudi: programStudi ?? this.programStudi,
      semester: semester ?? this.semester,
      ipkKumulatif: ipkKumulatif ?? this.ipkKumulatif,
      sksTempuh: sksTempuh ?? this.sksTempuh,
      angkatan: angkatan ?? this.angkatan,
      jenjang: jenjang ?? this.jenjang,
      telp: telp ?? this.telp,
      status: status ?? this.status,
      isAddEmail: isAddEmail ?? this.isAddEmail,
      emailVerification: emailVerification ?? this.emailVerification,
      email: email ?? this.email,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      batasSubscribe: batasSubscribe ?? this.batasSubscribe,
      modeSubscribe: modeSubscribe ?? this.modeSubscribe,
      midtransMerchantUrl: midtransMerchantUrl ?? this.midtransMerchantUrl,
      midtransClientKey: midtransClientKey ?? this.midtransClientKey,
      minAngkatanSubs: minAngkatanSubs ?? this.minAngkatanSubs,
      lockFitur: lockFitur ?? this.lockFitur,
    );
  }
}
