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
}
