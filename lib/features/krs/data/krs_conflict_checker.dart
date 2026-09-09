// Schedule-conflict detection for Input KRS.
// 1:1 port of the legacy `KrsMKAdapterChilditemJadwal.check()` — a pure
// function so it can be unit-tested (test/krs_conflict_checker_test.dart).

/// One already-selected schedule to check against (from another course).
class KrsSelectedSchedule {
  final String? jadwalHari;
  final String? jadwalJam;
  final String? namaMakul;

  const KrsSelectedSchedule({
    this.jadwalHari,
    this.jadwalJam,
    this.namaMakul,
  });
}

/// Returns the conflicting course name, or null when the target schedule is
/// safe to pick.
///
/// Legacy rules:
/// 1. Only compares against selections from OTHER courses
///    (`row.nama_makul != jadwal.makul`).
/// 2. Precondition: same day, both stored day/jam non-empty non-null.
/// 3. Time format "HH.mm-HH.mm" / "HH,mm-HH,mm": split on "-", replace
///    [,.] with ":" then parse "HH:mm" on both sides; unparseable -> skip.
/// 4. Conflict when:
///    (A.start >= B.start && A.start < B.end)   // starts inside B
///    || (A.end > B.start && A.end < B.end)      // ends inside B
///    || (A.start <= B.start && A.end >= B.end)  // fully covers B
///    Strict boundaries: back-to-back classes (09.00-11.00 vs 07.00-09.00)
///    are NOT a conflict.
String? findScheduleConflict({
  required Iterable<KrsSelectedSchedule> selected,
  required String? targetHari,
  required String? targetJam,
  required String? targetNamaMakul,
}) {
  if (targetHari == null || targetJam == null) return null;

  final target = _parseRange(targetJam);
  if (target == null) return null;

  for (final row in selected) {
    if (row.namaMakul == targetNamaMakul) continue; // same course: skip

    if (row.jadwalHari != targetHari) continue;
    if (row.jadwalHari == '' || row.jadwalJam == '' || row.jadwalJam == null) {
      continue;
    }

    final stored = _parseRange(row.jadwalJam!);
    if (stored == null) continue;

    final aStart = target.$1, aEnd = target.$2;
    final bStart = stored.$1, bEnd = stored.$2;

    final conflicts = (aStart >= bStart && aStart < bEnd) ||
        (aEnd > bStart && aEnd < bEnd) ||
        (aStart <= bStart && aEnd >= bEnd);
    if (conflicts) return row.namaMakul;
  }
  return null;
}

/// Parses "07.30-09.10" / "07,30-09,10" / "07:30-09:10" into (start, end)
/// minutes-since-midnight. Returns null when the string is not exactly two
/// valid HH:mm parts (legacy skips those rows).
(int, int)? _parseRange(String jam) {
  final parts = jam.split('-');
  if (parts.length != 2) return null;

  final start = _parseHm(parts[0].replaceAll(RegExp(r'[,.]'), ':'));
  final end = _parseHm(parts[1].replaceAll(RegExp(r'[,.]'), ':'));
  if (start == null || end == null) return null;

  return (start, end);
}

/// Parses a single "HH:mm" into minutes since midnight.
int? _parseHm(String s) {
  final normalized = s.trim();
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(normalized);
  if (m == null) return null;
  final h = int.tryParse(m.group(1)!);
  final min = int.tryParse(m.group(2)!);
  if (h == null || min == null || h > 23 || min > 59) return null;
  return h * 60 + min;
}
