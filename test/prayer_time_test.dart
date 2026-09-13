import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartmahsiswaflutter/features/prayer_time/data/models/prayer_timing_model.dart';

void main() {
  group('Prayer Timing Model & Display Tests', () {
    test('PrayerTimingModel fields are instantiated correctly', () {
      final model = PrayerTimingModel(
        imsak: '04:15',
        fajr: '04:25',
        sunrise: '05:40',
        dhuhr: '11:45',
        asr: '15:05',
        maghrib: '17:50',
        isha: '18:59',
        readableDate: '13 Sep 2026',
        gregorianDate: '13-09-2026',
        hijriDay: '1',
        hijriMonthNumber: 3,
        hijriMonthNameEn: 'Rabiul Awwal',
        hijriMonthNameAr: 'ربيع الأول',
        hijriYear: '1448',
        hijriWeekdayEn: 'Sunday',
        hijriWeekdayAr: 'الأحد',
        latitude: -7.33,
        longitude: 110.50,
        timezone: 'Asia/Jakarta',
        methodName: 'Kemenag RI',
      );

      expect(model.fajr, '04:25');
      expect(model.dhuhr, '11:45');
      expect(model.maghrib, '17:50');
      expect(model.hijriYear, '1448');
    });

    testWidgets('Prayer time countdown text fits in row without overflow', (WidgetTester tester) async {
      // Simulate small width screen (320px) to verify that long text does not overflow
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              width: 320,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'JADWAL SHOLAT BERIKUTNYA YANG SANGAT PANJANG SEKALI',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sholat Dzuhur Berjamaah di Masjid Kampus',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '11:45 WIB (Waktu Indonesia Barat)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('01:23:45'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsWidgets);
      expect(find.text('01:23:45'), findsOneWidget);
      // Verify no RenderFlex overflow exception occurred
      expect(tester.takeException(), isNull);
    });
  });
}
