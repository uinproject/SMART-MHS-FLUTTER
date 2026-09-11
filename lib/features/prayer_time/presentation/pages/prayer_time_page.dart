import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:smartmahsiswaflutter/core/theme/app_colors.dart';
import 'package:smartmahsiswaflutter/core/utils/location_helper.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../../data/models/prayer_timing_model.dart';
import '../../data/services/prayer_time_service.dart';
import '../../../qibla/presentation/pages/qibla_page.dart';

class PrayerTimePage extends StatefulWidget {
  const PrayerTimePage({super.key});

  @override
  State<PrayerTimePage> createState() => _PrayerTimePageState();
}

class _PrayerTimePageState extends State<PrayerTimePage> {
  final PrayerTimeService _prayerTimeService = PrayerTimeService();

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isLocationServiceEnabled = true;
  LocationPermission _locationPermission = LocationPermission.whileInUse;

  PrayerTimingModel? _prayerModel;
  String? _errorMessage;
  String? _displayAddress;

  Timer? _countdownTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Gunakan Future.microtask untuk memicu inisialisasi lokasi dan jadwal sholat
    Future.microtask(() {
      _initPrayerFeature();
    });

    // Realtime timer untuk hitung mundur sholat berikutnya tiap detik
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _initPrayerFeature({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      // 1. Check Location Service
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLocationServiceEnabled = false;
            _isLoading = false;
            _isRefreshing = false;
          });
        }
        return;
      } else {
        if (mounted) {
          setState(() {
            _isLocationServiceEnabled = true;
          });
        }
      }

      // 2. Check Permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (mounted) {
        setState(() {
          _locationPermission = permission;
        });
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isRefreshing = false;
          });
        }
        return;
      }

      // 3. Get GPS Position
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      // Default fallback coordinates (Salatiga/Indonesia) if GPS unavailable
      final lat = position?.latitude ?? -7.3305;
      final lng = position?.longitude ?? 110.5084;

      // 4. Reverse geocode coordinates to human-readable address (e.g. Sidorejo, Salatiga)
      String? address;
      try {
        address = await LocationHelper.getAddressFromCoordinates(lat, lng);
      } catch (_) {}

      // 5. Fetch Prayer Times (AlAdhan API method=20 / SharedPreferences Cache)
      final result = await _prayerTimeService.getPrayerTimes(
        latitude: lat,
        longitude: lng,
        currentAddress: address,
        forceRefresh: forceRefresh,
      );

      if (mounted) {
        setState(() {
          _prayerModel = result.model;
          _errorMessage = result.errorMessage;
          _displayAddress = result.address ?? address ?? 'Salatiga';
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = 'Terjadi kesalahan sistem. Silakan coba beberapa saat lagi.';
        });
      }
    }
  }

  /// Parses "HH:mm" into a today's DateTime
  DateTime? _parseTime(String timeStr, DateTime now, {int dayOffset = 0}) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0].trim());
        final minute = int.parse(parts[1].trim());
        return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
      }
    } catch (_) {}
    return null;
  }

  /// Determines next prayer name, target DateTime, and key
  Map<String, dynamic> _getNextPrayerInfo(PrayerTimingModel model, DateTime now) {
    final fajr = _parseTime(model.fajr, now);
    final dhuhr = _parseTime(model.dhuhr, now);
    final asr = _parseTime(model.asr, now);
    final maghrib = _parseTime(model.maghrib, now);
    final isha = _parseTime(model.isha, now);

    if (fajr == null || dhuhr == null || asr == null || maghrib == null || isha == null) {
      return {'key': 'fajr', 'time': DateTime.now(), 'isTomorrow': false};
    }

    if (now.isBefore(fajr)) {
      return {'key': 'fajr', 'target': fajr, 'isTomorrow': false, 'timeStr': model.fajr};
    } else if (now.isBefore(dhuhr)) {
      return {'key': 'dhuhr', 'target': dhuhr, 'isTomorrow': false, 'timeStr': model.dhuhr};
    } else if (now.isBefore(asr)) {
      return {'key': 'asr', 'target': asr, 'isTomorrow': false, 'timeStr': model.asr};
    } else if (now.isBefore(maghrib)) {
      return {'key': 'maghrib', 'target': maghrib, 'isTomorrow': false, 'timeStr': model.maghrib};
    } else if (now.isBefore(isha)) {
      return {'key': 'isha', 'target': isha, 'isTomorrow': false, 'timeStr': model.isha};
    } else {
      // Setelah waktu Isya, sholat berikutnya adalah Subuh esok hari
      final tomorrowFajr = _parseTime(model.fajr, now, dayOffset: 1);
      return {
        'key': 'fajr',
        'target': tomorrowFajr ?? fajr.add(const Duration(days: 1)),
        'isTomorrow': true,
        'timeStr': model.fajr,
      };
    }
  }

  /// Formats duration without minus sign
  String _formatCountdown(Duration diff) {
    if (diff.isNegative) return '00:00:00';
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _getPrayerLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'fajr':
        return l10n.fajr;
      case 'sunrise':
        return l10n.sunrise;
      case 'dhuhr':
        return l10n.dhuhr;
      case 'asr':
        return l10n.asr;
      case 'maghrib':
        return l10n.maghrib;
      case 'isha':
        return l10n.isha;
      case 'imsak':
        return l10n.imsak;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF003D82), Color(0xFF0056B3)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.prayerSchedule,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_isRefreshing)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => _initPrayerFeature(forceRefresh: true),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(context, l10n, locale),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n, Locale locale) {
    // 1. Loading State: Menggunakan SpinKitThreeBounce sesuai standar halaman project (contoh: Riwayat Akademik)
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.32),
          const Center(
            child: SpinKitThreeBounce(color: AppColors.primary, size: 30),
          ),
        ],
      );
    }

    // 2. Location Permission denied state
    if (_locationPermission == LocationPermission.denied ||
        _locationPermission == LocationPermission.deniedForever) {
      return _buildPermissionCard(l10n);
    }

    // 3. Location service disabled (GPS off)
    if (!_isLocationServiceEnabled) {
      return _buildGpsDisabledCard(l10n);
    }

    // 4. Error state without any data
    if (_prayerModel == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          const Center(
            child: Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? l10n.systemError,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _initPrayerFeature(forceRefresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.tryAgain),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final model = _prayerModel!;
    final nextPrayerInfo = _getNextPrayerInfo(model, _currentTime);
    final targetTime = nextPrayerInfo['target'] as DateTime;
    final remainingDiff = targetTime.difference(_currentTime);
    final isTomorrow = nextPrayerInfo['isTomorrow'] as bool;
    final nextPrayerKey = nextPrayerInfo['key'] as String;
    final nextPrayerLabel = isTomorrow
        ? '${_getPrayerLabel(l10n, nextPrayerKey)} (${l10n.tomorrowFajr})'
        : _getPrayerLabel(l10n, nextPrayerKey);

    // Fasting info: Ramadhan, Senin-Kamis, Ayyamul Bidh, etc.
    final fastingInfo = model.getFastingInfo(_currentTime);

    // 5. Success State: Menggunakan ListView dengan AlwaysScrollableScrollPhysics agar swipe-to-refresh
    // selalu responsif di area manapun (termasuk saat menyentuh card sholat)
    return RefreshIndicator(
      onRefresh: () => _initPrayerFeature(forceRefresh: true),
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Top Countdown Hero Card
          _buildNextPrayerHeroCard(
            l10n: l10n,
            locale: locale,
            model: model,
            nextPrayerLabel: nextPrayerLabel,
            nextPrayerTime: nextPrayerInfo['timeStr']?.toString() ?? '',
            remainingDiff: remainingDiff,
          ),
          const SizedBox(height: 18),

          // Fasting Schedule Card (Only shown if today has fasting schedule)
          if (fastingInfo.isFasting) ...[
            _buildFastingCard(l10n, locale, model, fastingInfo),
            const SizedBox(height: 18),
          ],

          // Prayer Times List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.prayerTimes,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      size: 13,
                      color: Color(0xFF003D82),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.kemenagMethod,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF003D82),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Prayer List Items: Subuh, Terbit, Dzuhur, Ashar, Maghrib, Isya
          _buildPrayerItem(
            l10n: l10n,
            name: l10n.fajr,
            time: model.fajr,
            icon: Icons.nightlight_round,
            isNext: nextPrayerKey == 'fajr',
          ),
          _buildPrayerItem(
            l10n: l10n,
            name: l10n.sunrise,
            time: model.sunrise,
            icon: Icons.wb_twilight_rounded,
            isNext: false,
            isSecondary: true,
          ),
          _buildPrayerItem(
            l10n: l10n,
            name: l10n.dhuhr,
            time: model.dhuhr,
            icon: Icons.wb_sunny_rounded,
            isNext: nextPrayerKey == 'dhuhr',
          ),
          _buildPrayerItem(
            l10n: l10n,
            name: l10n.asr,
            time: model.asr,
            icon: Icons.filter_drama_rounded,
            isNext: nextPrayerKey == 'asr',
          ),
          _buildPrayerItem(
            l10n: l10n,
            name: l10n.maghrib,
            time: model.maghrib,
            icon: Icons.wb_twilight_rounded,
            isNext: nextPrayerKey == 'maghrib',
          ),
          _buildPrayerItem(
            l10n: l10n,
            name: l10n.isha,
            time: model.isha,
            icon: Icons.bedtime_rounded,
            isNext: nextPrayerKey == 'isha',
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Hero Card with next prayer, clean countdown (no '-' or 'dalam'), and human-readable address
  Widget _buildNextPrayerHeroCard({
    required AppLocalizations l10n,
    required Locale locale,
    required PrayerTimingModel model,
    required String nextPrayerLabel,
    required String nextPrayerTime,
    required Duration remainingDiff,
  }) {
    // Clean Hijri date using standard ASCII characters to avoid font corruption with macrons
    final cleanHijriMonth = model.getCleanHijriMonthName(locale.languageCode);
    final hijriStr = '${model.hijriDay} $cleanHijriMonth ${model.hijriYear} H';

    // Gregorian date string
    final gregStr = DateFormat('EEEE, d MMMM yyyy', locale.languageCode).format(_currentTime);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF003D82), Color(0xFF0056B3)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003D82).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dates Header & Human-readable Location
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gregStr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hijriStr,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFFFBBF24), // Gold accent
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (_displayAddress != null && _displayAddress!.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxWidth: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFFBBF24),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _displayAddress!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 18),

          // Next Prayer Info & Clean User-Friendly Countdown (Tanpa tanda minus dan tanpa kata 'dalam')
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.nextPrayer,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextPrayerLabel,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nextPrayerTime,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFBBF24),
                    ),
                  ),
                ],
              ),
              // Clean digital countdown display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: Color(0xFFFBBF24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatCountdown(remainingDiff),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),

          // Qibla Direction Action inside Hero Card
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QiblaPage()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.explore_rounded,
                        color: Color(0xFFFBBF24),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.qiblaDirection,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            l10n.qiblaCompass,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dedicated Fasting Card (Ramadhan, Senin-Kamis, Ayyamul Bidh, etc.)
  Widget _buildFastingCard(
    AppLocalizations l10n,
    Locale locale,
    PrayerTimingModel model,
    FastingInfo fastingInfo,
  ) {
    String fastingName = fastingInfo.nameId;
    if (locale.languageCode == 'en') {
      fastingName = fastingInfo.nameEn;
    } else if (locale.languageCode == 'ar') {
      fastingName = fastingInfo.nameAr;
    }

    final imsakTime = _parseTime(model.imsak, _currentTime);
    final maghribTime = _parseTime(model.maghrib, _currentTime);

    String statusText = '';
    String countdownText = '';

    if (imsakTime != null && _currentTime.isBefore(imsakTime)) {
      statusText = l10n.timeUntilImsak;
      countdownText = _formatCountdown(imsakTime.difference(_currentTime));
    } else if (maghribTime != null && _currentTime.isBefore(maghribTime)) {
      statusText = l10n.timeUntilIftar;
      countdownText = _formatCountdown(maghribTime.difference(_currentTime));
    } else {
      statusText = l10n.breakFasting;
      countdownText = model.maghrib;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.nights_stay_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.fastingSchedule,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      fastingName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 13,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      countdownText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF059669),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildFastingTimeColumn(
                  label: l10n.imsak,
                  time: model.imsak,
                  icon: Icons.alarm_rounded,
                  iconColor: const Color(0xFF003D82),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: const Color(0xFFE2E8F0),
              ),
              Expanded(
                child: _buildFastingTimeColumn(
                  label: l10n.breakFasting,
                  time: model.maghrib,
                  icon: Icons.restaurant_rounded,
                  iconColor: const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              statusText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFastingTimeColumn({
    required String label,
    required String time,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  /// Individual prayer time row item
  Widget _buildPrayerItem({
    required AppLocalizations l10n,
    required String name,
    required String time,
    required IconData icon,
    required bool isNext,
    bool isSecondary = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isNext ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNext ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
          width: isNext ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isNext
                ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isNext
                  ? AppColors.primary
                  : (isSecondary
                      ? const Color(0xFFF1F5F9)
                      : AppColors.primary.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isNext
                  ? Colors.white
                  : (isSecondary ? const Color(0xFF64748B) : AppColors.primary),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                        color: isSecondary
                            ? const Color(0xFF64748B)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                    if (isNext) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          l10n.nextPrayer,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isNext ? AppColors.primary : const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  /// Card requesting location permission
  Widget _buildPermissionCard(AppLocalizations l10n) {
    final isPermanent = _locationPermission == LocationPermission.deniedForever;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFDE68A), width: 2),
              ),
              child: const Icon(
                Icons.location_off_rounded,
                color: Color(0xFFD97706),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.locationPermissionRequired,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.prayerLocationPermissionDesc,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (isPermanent) {
                  await Geolocator.openAppSettings();
                } else {
                  await _initPrayerFeature();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                isPermanent ? l10n.openSettings : l10n.grantPermission,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card when device GPS is turned off
  Widget _buildGpsDisabledCard(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
              ),
              child: const Icon(
                Icons.gps_off_rounded,
                color: Color(0xFF2563EB),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.locationDisabled,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.locationDisabledDesc,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
                _initPrayerFeature();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.enableLocation,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
