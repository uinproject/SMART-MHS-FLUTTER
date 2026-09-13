import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartmahsiswaflutter/features/home/data/models/pengumuman_response.dart';
import 'package:smartmahsiswaflutter/features/home/data/storage/home_cache_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HomeCacheStorage Tests', () {
    const testNim = '210101099';

    final testResponse = PengumumanResponse(
      success: true,
      message: 'OK',
      pesanPenting: 'Harap segera melakukan validasi KRS sebelum 20 September 2026',
      aksiPesan: 'krs',
      cekEval: true,
      data: [
        PengumumanData(
          judul: 'Wisuda Periode III Tahun 2026',
          linkPicture: 'https://uinsalatiga.ac.id/wisuda.jpg',
          isi: '<p>Pendaftaran wisuda telah dibuka...</p>',
          tanggal: '2026-09-12',
          kategori: 'Akademik',
          publisher: 'TIPD',
          cekEval: true,
        ),
        PengumumanData(
          judul: 'Jadwal Pembayaran UKT Semester Genap',
          linkPicture: 'https://uinsalatiga.ac.id/ukt.jpg',
          isi: '<p>Pembayaran dapat dilakukan melalui Bank Jateng Syariah...</p>',
          tanggal: '2026-09-10',
          kategori: 'Keuangan',
          publisher: 'Keuangan',
          cekEval: true,
        ),
      ],
    );

    test('toJson and fromJson preserves all PengumumanResponse and PengumumanData fields', () {
      final json = testResponse.toJson();
      final restored = PengumumanResponse.fromJson(json);

      expect(restored.success, equals(testResponse.success));
      expect(restored.pesanPenting, equals(testResponse.pesanPenting));
      expect(restored.aksiPesan, equals(testResponse.aksiPesan));
      expect(restored.cekEval, equals(testResponse.cekEval));
      expect(restored.data?.length, equals(2));
      expect(restored.data?[0].judul, equals('Wisuda Periode III Tahun 2026'));
      expect(restored.data?[0].linkPicture, equals('https://uinsalatiga.ac.id/wisuda.jpg'));
      expect(restored.data?[1].judul, equals('Jadwal Pembayaran UKT Semester Genap'));
    });

    test('savePengumuman and loadPengumuman caches and restores data for specific student NIM', () async {
      // 1. Initial load should be null
      final initial = await HomeCacheStorage.loadPengumuman(testNim);
      expect(initial, isNull);

      // 2. Save cache
      await HomeCacheStorage.savePengumuman(testNim, testResponse);

      // 3. Load cache
      final cached = await HomeCacheStorage.loadPengumuman(testNim);
      expect(cached, isNotNull);
      expect(cached!.pesanPenting, equals('Harap segera melakukan validasi KRS sebelum 20 September 2026'));
      expect(cached.data?.length, equals(2));
      expect(cached.data?.first.judul, equals('Wisuda Periode III Tahun 2026'));

      // 4. Check last updated timestamp
      final lastUpdated = await HomeCacheStorage.getLastUpdated(testNim);
      expect(lastUpdated, isNotNull);
      expect(DateTime.now().difference(lastUpdated!).inSeconds, lessThan(5));
    });

    test('clearPengumuman removes cached data', () async {
      await HomeCacheStorage.savePengumuman(testNim, testResponse);
      final beforeClear = await HomeCacheStorage.loadPengumuman(testNim);
      expect(beforeClear, isNotNull);

      await HomeCacheStorage.clearPengumuman(testNim);
      final afterClear = await HomeCacheStorage.loadPengumuman(testNim);
      expect(afterClear, isNull);
    });
  });
}
