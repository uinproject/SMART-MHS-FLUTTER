// POST payload for krsservices/input_krs_mata_kuliah.
// Mirrors the legacy Kotlin model `KrsMKformatdata` — serialized names must
// match exactly because the JSON string is hashed and sent as the
// `data_input_krs_mk` form field.
import 'krs_list_response.dart';

class KrsInputItem {
  final String kodeMk;
  final String nodos;
  final int sksMk;
  final String jadwalHari;
  final String jadwalJam;
  final String jadwalKelas;
  final String jadwalRuang;
  final String isacc;

  KrsInputItem({
    required this.kodeMk,
    required this.nodos,
    required this.sksMk,
    required this.jadwalHari,
    required this.jadwalJam,
    required this.jadwalKelas,
    required this.jadwalRuang,
    required this.isacc,
  });

  factory KrsInputItem.fromJadwal(KrsJadwal j) {
    return KrsInputItem(
      kodeMk: j.kodeMk,
      nodos: j.nodos ?? '',
      sksMk: j.sksMk,
      jadwalHari: j.jadwalHari,
      jadwalJam: j.jadwalJam,
      jadwalKelas: j.jadwalKelas,
      jadwalRuang: j.jadwalRuang,
      isacc: j.isacc,
    );
  }

  Map<String, dynamic> toJson() => {
        'kode_mk': kodeMk,
        'nodos': nodos,
        'sks_mk': sksMk,
        'jadwal_hari': jadwalHari,
        'jadwal_jam': jadwalJam,
        'jadwal_kelas': jadwalKelas,
        'jadwal_ruang': jadwalRuang,
        'isacc': isacc,
      };
}
