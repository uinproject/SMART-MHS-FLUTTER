class PrayerTimingModel {
  final String imsak;
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;

  final String readableDate;
  final String gregorianDate; // DD-MM-YYYY
  final String hijriDay;
  final int hijriMonthNumber;
  final String hijriMonthNameEn;
  final String hijriMonthNameAr;
  final String hijriYear;
  final String hijriWeekdayEn;
  final String hijriWeekdayAr;

  final double latitude;
  final double longitude;
  final String timezone;
  final String methodName;

  PrayerTimingModel({
    required this.imsak,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.readableDate,
    required this.gregorianDate,
    required this.hijriDay,
    required this.hijriMonthNumber,
    required this.hijriMonthNameEn,
    required this.hijriMonthNameAr,
    required this.hijriYear,
    required this.hijriWeekdayEn,
    required this.hijriWeekdayAr,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.methodName,
  });

  static String _cleanTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';
    // Clean "(WIB)" or any suffix
    return time.split(' ').first.trim();
  }

  factory PrayerTimingModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final timings = data['timings'] as Map<String, dynamic>? ?? {};
    final date = data['date'] as Map<String, dynamic>? ?? {};
    final hijri = date['hijri'] as Map<String, dynamic>? ?? {};
    final gregorian = date['gregorian'] as Map<String, dynamic>? ?? {};
    final meta = data['meta'] as Map<String, dynamic>? ?? {};
    final method = meta['method'] as Map<String, dynamic>? ?? {};

    return PrayerTimingModel(
      imsak: _cleanTime(timings['Imsak']?.toString()),
      fajr: _cleanTime(timings['Fajr']?.toString()),
      sunrise: _cleanTime(timings['Sunrise']?.toString()),
      dhuhr: _cleanTime(timings['Dhuhr']?.toString()),
      asr: _cleanTime(timings['Asr']?.toString()),
      maghrib: _cleanTime(timings['Maghrib']?.toString()),
      isha: _cleanTime(timings['Isha']?.toString()),
      readableDate: date['readable']?.toString() ?? '',
      gregorianDate: gregorian['date']?.toString() ?? '',
      hijriDay: hijri['day']?.toString() ?? '',
      hijriMonthNumber: int.tryParse(hijri['month']?['number']?.toString() ?? '0') ?? 0,
      hijriMonthNameEn: hijri['month']?['en']?.toString() ?? '',
      hijriMonthNameAr: hijri['month']?['ar']?.toString() ?? '',
      hijriYear: hijri['year']?.toString() ?? '',
      hijriWeekdayEn: hijri['weekday']?['en']?.toString() ?? '',
      hijriWeekdayAr: hijri['weekday']?['ar']?.toString() ?? '',
      latitude: (meta['latitude'] is num) ? (meta['latitude'] as num).toDouble() : 0.0,
      longitude: (meta['longitude'] is num) ? (meta['longitude'] as num).toDouble() : 0.0,
      timezone: meta['timezone']?.toString() ?? 'Asia/Jakarta',
      methodName: method['name']?.toString() ?? 'Kementerian Agama Republik Indonesia',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'timings': {
          'Imsak': imsak,
          'Fajr': fajr,
          'Sunrise': sunrise,
          'Dhuhr': dhuhr,
          'Asr': asr,
          'Maghrib': maghrib,
          'Isha': isha,
        },
        'date': {
          'readable': readableDate,
          'gregorian': {'date': gregorianDate},
          'hijri': {
            'day': hijriDay,
            'month': {
              'number': hijriMonthNumber,
              'en': hijriMonthNameEn,
              'ar': hijriMonthNameAr,
            },
            'year': hijriYear,
            'weekday': {
              'en': hijriWeekdayEn,
              'ar': hijriWeekdayAr,
            },
          },
        },
        'meta': {
          'latitude': latitude,
          'longitude': longitude,
          'timezone': timezone,
          'method': {'name': methodName},
        },
      }
    };
  }

  /// Returns clean, standard ASCII Hijri month name supporting ID, EN, and AR
  /// to avoid font glyph / rendering issues with diacritic macrons (e.g. Rabīʿ)
  String getCleanHijriMonthName(String languageCode) {
    if (languageCode == 'ar') {
      switch (hijriMonthNumber) {
        case 1: return 'محرم';
        case 2: return 'صفر';
        case 3: return 'ربيع الأول';
        case 4: return 'ربيع الآخر';
        case 5: return 'جمادى الأولى';
        case 6: return 'جمادى الآخرة';
        case 7: return 'رجب';
        case 8: return 'شعبان';
        case 9: return 'رمضان';
        case 10: return 'شوال';
        case 11: return 'ذو القعدة';
        case 12: return 'ذو الحجة';
        default: return hijriMonthNameAr.isNotEmpty ? hijriMonthNameAr : 'رمضان';
      }
    } else if (languageCode == 'id') {
      switch (hijriMonthNumber) {
        case 1: return 'Muharram';
        case 2: return 'Safar';
        case 3: return 'Rabiul Awwal';
        case 4: return 'Rabiul Akhir';
        case 5: return 'Jumadil Awwal';
        case 6: return 'Jumadil Akhir';
        case 7: return 'Rajab';
        case 8: return 'Sya\'ban';
        case 9: return 'Ramadhan';
        case 10: return 'Syawwal';
        case 11: return 'Dzulqa\'dah';
        case 12: return 'Dzulhijjah';
        default: return hijriMonthNameEn;
      }
    } else {
      switch (hijriMonthNumber) {
        case 1: return 'Muharram';
        case 2: return 'Safar';
        case 3: return 'Rabi al-Awwal';
        case 4: return 'Rabi al-Thani';
        case 5: return 'Jumada al-Awwal';
        case 6: return 'Jumada al-Thani';
        case 7: return 'Rajab';
        case 8: return 'Sha\'ban';
        case 9: return 'Ramadan';
        case 10: return 'Shawwal';
        case 11: return 'Dhu al-Qi\'dah';
        case 12: return 'Dhu al-Hijjah';
        default: return hijriMonthNameEn;
      }
    }
  }

  /// Evaluates whether today qualifies as a fasting day:
  /// - Ramadan (Hijri month 9)
  /// - Sunnah Monday or Thursday
  /// - Sunnah Ayyamul Bidh (13, 14, 15 Hijri except 13 Dzulhijjah)
  /// - Arafah (9 Dzulhijjah)
  /// - Asyura / Tasu'a (10 & 9 Muharram)
  FastingInfo getFastingInfo(DateTime now) {
    // 1. Ramadan
    if (hijriMonthNumber == 9) {
      return FastingInfo(
        isFasting: true,
        type: FastingType.ramadhan,
        nameId: 'Puasa Ramadhan',
        nameEn: 'Ramadan Fasting',
        nameAr: 'صيام رمضان',
      );
    }

    final day = int.tryParse(hijriDay) ?? 0;

    // 2. Arafah (9 Dzulhijjah)
    if (hijriMonthNumber == 12 && day == 9) {
      return FastingInfo(
        isFasting: true,
        type: FastingType.arafah,
        nameId: 'Puasa Sunnah Arafah',
        nameEn: 'Arafah Fasting',
        nameAr: 'صيام يوم عرفة',
      );
    }

    // 3. Tasu'a (9 Muharram)
    if (hijriMonthNumber == 1 && day == 9) {
      return FastingInfo(
        isFasting: true,
        type: FastingType.tasuah,
        nameId: 'Puasa Sunnah Tasu\'a',
        nameEn: 'Tasu\'a Fasting',
        nameAr: 'صيام يوم تاسوعاء',
      );
    }

    // 4. Asyura (10 Muharram)
    if (hijriMonthNumber == 1 && day == 10) {
      return FastingInfo(
        isFasting: true,
        type: FastingType.asyura,
        nameId: 'Puasa Sunnah Asyura',
        nameEn: 'Ashura Fasting',
        nameAr: 'صيام يوم عاشوراء',
      );
    }

    // 5. Ayyamul Bidh (13, 14, 15 Hijri, except 13 Dzulhijjah because it is Hari Tasyrik)
    if ((day == 13 || day == 14 || day == 15) && !(hijriMonthNumber == 12 && day == 13)) {
      return FastingInfo(
        isFasting: true,
        type: FastingType.ayyamulBidh,
        nameId: 'Puasa Sunnah Ayyamul Bidh',
        nameEn: 'Ayyamul Bidh Fasting',
        nameAr: 'صيام الأيام البيض',
      );
    }

    // 6. Monday or Thursday
    if (now.weekday == DateTime.monday) {
      return FastingInfo(
        isFasting: true,
        type: FastingType.monday,
        nameId: 'Puasa Sunnah Senin',
        nameEn: 'Monday Fasting',
        nameAr: 'صيام يوم الإثنين',
      );
    } else if (now.weekday == DateTime.thursday) {
      return FastingInfo(
        isFasting: true,
        type: FastingType.thursday,
        nameId: 'Puasa Sunnah Kamis',
        nameEn: 'Thursday Fasting',
        nameAr: 'صيام يوم الخميس',
      );
    }

    return FastingInfo(isFasting: false);
  }
}

enum FastingType {
  none,
  ramadhan,
  monday,
  thursday,
  ayyamulBidh,
  arafah,
  asyura,
  tasuah,
}

class FastingInfo {
  final bool isFasting;
  final FastingType type;
  final String nameId;
  final String nameEn;
  final String nameAr;

  FastingInfo({
    required this.isFasting,
    this.type = FastingType.none,
    this.nameId = '',
    this.nameEn = '',
    this.nameAr = '',
  });
}
