import 'package:flutter_test/flutter_test.dart';
import 'package:smartmahsiswaflutter/features/krs/data/krs_conflict_checker.dart';

void main() {
  const stored = KrsSelectedSchedule(
    jadwalHari: 'Senin',
    jadwalJam: '07.00-09.00',
    namaMakul: 'Algoritma Pemrograman',
  );

  String? check(String? jam, {String? hari = 'Senin', String? makul = 'Basis Data'}) {
    return findScheduleConflict(
      selected: const [stored],
      targetHari: hari,
      targetJam: jam,
      targetNamaMakul: makul,
    );
  }

  group('bentrok (harus ditolak)', () {
    test('rentang identik', () {
      expect(check('07.00-09.00'), 'Algoritma Pemrograman');
    });

    test('mulai di tengah jadwal tersimpan', () {
      expect(check('08.00-10.00'), 'Algoritma Pemrograman');
    });

    test('berakhir di tengah jadwal tersimpan', () {
      expect(check('06.00-08.00'), 'Algoritma Pemrograman');
    });

    test('melingkupi penuh jadwal tersimpan', () {
      expect(check('06.00-10.00'), 'Algoritma Pemrograman');
    });

    test('format koma "07,30-09,10" vs "07.30-09.10" terparse & bentrok', () {
      const storedComma = KrsSelectedSchedule(
        jadwalHari: 'Selasa',
        jadwalJam: '07,30-09,10',
        namaMakul: 'Matematika Diskrit',
      );
      final result = findScheduleConflict(
        selected: const [storedComma],
        targetHari: 'Selasa',
        targetJam: '08.00-09.00',
        targetNamaMakul: 'Basis Data',
      );
      expect(result, 'Matematika Diskrit');
    });

    test('overlap sebagian di ujung akhir', () {
      expect(check('08.30-10.30'), 'Algoritma Pemrograman');
    });
  });

  group('aman (tidak bentrok)', () {
    test('berdampingan jam tepat (batas ketat)', () {
      expect(check('09.00-11.00'), isNull);
    });

    test('sebelum jadwal tersimpan berdampingan', () {
      expect(check('05.00-07.00'), isNull);
    });

    test('hari berbeda', () {
      expect(check('07.00-09.00', hari: 'Selasa'), isNull);
    });

    test('makul sama tidak dicek (ganti kelas)', () {
      expect(check('07.00-09.00', makul: 'Algoritma Pemrograman'), isNull);
    });

    test('target jam null', () {
      expect(check(null), isNull);
    });

    test('target hari null', () {
      final result = findScheduleConflict(
        selected: const [stored],
        targetHari: null,
        targetJam: '07.00-09.00',
        targetNamaMakul: 'Basis Data',
      );
      expect(result, isNull);
    });

    test('jadwal tersimpan kosong / tidak dijadwalkan diabaikan', () {
      const notScheduled = KrsSelectedSchedule(
        jadwalHari: '',
        jadwalJam: '',
        namaMakul: 'Skripsi',
      );
      final result = findScheduleConflict(
        selected: const [notScheduled],
        targetHari: 'Senin',
        targetJam: '07.00-09.00',
        targetNamaMakul: 'Basis Data',
      );
      expect(result, isNull);
    });

    test('format jam tidak valid diabaikan', () {
      expect(check('makan-malam'), isNull);
      expect(check('07.00'), isNull);
    });
  });
}
