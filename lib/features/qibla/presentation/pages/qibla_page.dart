import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:smartmahsiswaflutter/core/theme/app_colors.dart';
import 'package:smartmahsiswaflutter/core/utils/location_helper.dart';
import 'package:smartmahsiswaflutter/l10n/app_localizations.dart';
import '../widgets/qibla_compass_painter.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Kaaba coordinates
  static const double _kaabaLat = 21.422487;
  static const double _kaabaLon = 39.826206;

  // State flags
  bool _isLoading = true;
  bool _isSensorSupported = true;
  bool _isLocationServiceEnabled = true;
  LocationPermission _locationPermission = LocationPermission.denied;
  bool _wasAligned = false;

  // Sensor and GPS data
  Position? _currentPosition;
  String? _displayAddress;
  double _qiblaAngle = 294.5; // Default approx for Indonesia
  double _distanceToKaabaKm = 0;
  double _continuousHeading = 0;
  double _currentHeadingDegrees = 0;

  StreamSubscription<CompassEvent>? _compassSubscription;
  Timer? _sensorTimeoutTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Gunakan Future.microtask untuk memicu inisialisasi sensor & GPS
    Future.microtask(() {
      _initQiblaFeature();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Saat pengguna kembali dari Settings iOS/Android, otomatis cek ulang izin lokasi
      if (_locationPermission != LocationPermission.whileInUse &&
          _locationPermission != LocationPermission.always) {
        _initQiblaFeature();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sensorTimeoutTimer?.cancel();
    _compassSubscription?.cancel();
    super.dispose();
  }

  /// Calculates the Qibla forward azimuth (bearing) from user's coordinates
  double _calculateQiblaBearing(double userLat, double userLon) {
    final phi1 = userLat * (math.pi / 180.0);
    final phi2 = _kaabaLat * (math.pi / 180.0);
    final deltaLam = (_kaabaLon - userLon) * (math.pi / 180.0);

    final y = math.sin(deltaLam);
    final x = math.cos(phi1) * math.tan(phi2) -
        math.sin(phi1) * math.cos(deltaLam);
    final qiblaRad = math.atan2(y, x);
    final qiblaDeg = qiblaRad * (180.0 / math.pi);
    return (qiblaDeg + 360.0) % 360.0;
  }

  Future<void> _initQiblaFeature() async {
    setState(() {
      _isLoading = true;
      _isSensorSupported = true;
    });

    final permissionGranted = await _checkAndRequestLocation();
    // Only setup compass if permission was granted and GPS is enabled
    if (permissionGranted) {
      _setupCompass();
    }
  }

  /// Returns true if location permission was granted and GPS is enabled.
  Future<bool> _checkAndRequestLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLocationServiceEnabled = false;
            _isLoading = false;
          });
        }
        return false;
      } else {
        if (mounted) {
          setState(() {
            _isLocationServiceEnabled = true;
          });
        }
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (mounted) {
        setState(() {
          _locationPermission = permission;
        });
      }

      // If permission was not granted, stop loading and show permission card
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return false;
      }

      // Permission granted — fetch GPS position
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos != null && mounted) {
        final angle = _calculateQiblaBearing(pos.latitude, pos.longitude);
        final distanceMeters = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          _kaabaLat,
          _kaabaLon,
        );

        String? address;
        try {
          address = await LocationHelper.getAddressFromCoordinates(pos.latitude, pos.longitude);
        } catch (_) {}

        if (mounted) {
          setState(() {
            _currentPosition = pos;
            _displayAddress = address;
            _qiblaAngle = angle;
            _distanceToKaabaKm = distanceMeters / 1000.0;
          });
        }
      }

      return true;
    } catch (_) {
      // On error, still return true to allow compass to try
      return true;
    }
  }

  void _setupCompass() {
    _sensorTimeoutTimer?.cancel();
    _compassSubscription?.cancel();

    final compassEvents = FlutterCompass.events;
    if (compassEvents == null) {
      if (mounted) {
        setState(() {
          _isSensorSupported = false;
          _isLoading = false;
        });
      }
      return;
    }

    // Set timeout to detect devices without functioning compass sensor
    _sensorTimeoutTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isLoading) {
        setState(() {
          _isSensorSupported = false;
          _isLoading = false;
        });
      }
    });

    _compassSubscription = compassEvents.listen(
      (CompassEvent event) {
        _sensorTimeoutTimer?.cancel();
        final rawHeading = event.heading;

        if (rawHeading == null) {
          if (mounted && _isLoading) {
            setState(() {
              _isSensorSupported = false;
              _isLoading = false;
            });
          }
          return;
        }

        if (!mounted) return;

        // Smooth shortest-path rotation calculation
        double diff = (rawHeading - (_continuousHeading % 360));
        if (diff > 180) diff -= 360;
        if (diff < -180) diff += 360;

        final newContinuous = _continuousHeading + diff;
        final normalizedHeading = (rawHeading % 360 + 360) % 360;

        // Check alignment with Qibla (tolerance ±3 degrees)
        final angleDiff =
            ((normalizedHeading - _qiblaAngle + 180) % 360 - 180).abs();
        final isAligned = angleDiff <= 3.0;

        if (isAligned && !_wasAligned) {
          HapticFeedback.selectionClick();
        }
        _wasAligned = isAligned;

        setState(() {
          _continuousHeading = newContinuous;
          _currentHeadingDegrees = normalizedHeading;
          _isSensorSupported = true;
          _isLoading = false;
        });
      },
      onError: (err) {
        _sensorTimeoutTimer?.cancel();
        if (mounted) {
          setState(() {
            _isSensorSupported = false;
            _isLoading = false;
          });
        }
      },
    );
  }

  void _showCalibrationGuide(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.explore_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        l10n.qiblaCompass,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sync_rounded,
                        color: Color(0xFF003D82),
                        size: 32,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l10n.calibrateCompassHint,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF334155),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.alignWithQibla,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);

    // Localized cardinal direction letters
    String northLabel = 'N';
    String eastLabel = 'E';
    String southLabel = 'S';
    String westLabel = 'W';

    if (locale.languageCode == 'id') {
      northLabel = 'U';
      eastLabel = 'T';
      southLabel = 'S';
      westLabel = 'B';
    } else if (locale.languageCode == 'ar') {
      northLabel = 'ش';
      eastLabel = 'ق';
      southLabel = 'ج';
      westLabel = 'غ';
    }

    final angleDiff =
        ((_currentHeadingDegrees - _qiblaAngle + 180) % 360 - 180).abs();
    final isAligned = angleDiff <= 3.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          color: AppColors.primary,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.qiblaDirection,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.info_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () => _showCalibrationGuide(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(
        context: context,
        l10n: l10n,
        northLabel: northLabel,
        eastLabel: eastLabel,
        southLabel: southLabel,
        westLabel: westLabel,
        isAligned: isAligned,
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required AppLocalizations l10n,
    required String northLabel,
    required String eastLabel,
    required String southLabel,
    required String westLabel,
    required bool isAligned,
  }) {
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

    // Check location permission state
    if (_locationPermission == LocationPermission.denied ||
        _locationPermission == LocationPermission.deniedForever) {
      return _buildLocationPermissionCard(l10n);
    }

    // Check GPS service state
    if (!_isLocationServiceEnabled) {
      return _buildLocationDisabledCard(l10n);
    }

    // Check if device lacks compass sensor
    if (!_isSensorSupported) {
      return _buildUnsupportedDeviceView(l10n);
    }

    // Active Compass Screen
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Alignment Status Pill
          _buildAlignmentStatusBanner(l10n, isAligned),
          const SizedBox(height: 24),

          // Main Compass Widget
          _buildCompassView(
            northLabel: northLabel,
            eastLabel: eastLabel,
            southLabel: southLabel,
            westLabel: westLabel,
            isAligned: isAligned,
          ),
          const SizedBox(height: 24),

          // Information Cards Grid
          _buildInfoCards(l10n),
          const SizedBox(height: 16),

          // Figure-8 Calibration Hint Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.screen_rotation_alt_rounded,
                    color: Color(0xFF003D82),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.calibrateCompassHint,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Status banner indicating if device is facing Qibla
  Widget _buildAlignmentStatusBanner(AppLocalizations l10n, bool isAligned) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: isAligned ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAligned ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
          width: isAligned ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isAligned
                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAligned
                ? Icons.check_circle_rounded
                : Icons.navigation_rounded,
            color: isAligned ? const Color(0xFF10B981) : const Color(0xFF003D82),
            size: 20,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              isAligned ? l10n.facingQibla : l10n.alignWithQibla,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isAligned ? FontWeight.bold : FontWeight.w600,
                color: isAligned
                    ? const Color(0xFF065F46)
                    : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The interactive compass dial and needle
  Widget _buildCompassView({
    required String northLabel,
    required String eastLabel,
    required String southLabel,
    required String westLabel,
    required bool isAligned,
  }) {
    final compassSize = MediaQuery.of(context).size.width * 0.78;

    return Center(
      child: Container(
        width: compassSize,
        height: compassSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: isAligned
                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                  : const Color(0xFF003D82).withValues(alpha: 0.08),
              blurRadius: isAligned ? 28 : 20,
              spreadRadius: isAligned ? 4 : 1,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rotating Compass Rose (Dial)
            AnimatedRotation(
              turns: -_continuousHeading / 360.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: CustomPaint(
                size: Size(compassSize, compassSize),
                painter: QiblaCompassPainter(
                  qiblaAngle: _qiblaAngle,
                  northLabel: northLabel,
                  eastLabel: eastLabel,
                  southLabel: southLabel,
                  westLabel: westLabel,
                  isAligned: isAligned,
                ),
              ),
            ),

            // Rotating Qibla Needle
            AnimatedRotation(
              turns: (_qiblaAngle - _continuousHeading) / 360.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: CustomPaint(
                size: Size(compassSize, compassSize),
                painter: QiblaNeedlePainter(isAligned: isAligned),
              ),
            ),

            // Top alignment indicator (Triangle notch at 12 o'clock)
            Positioned(
              top: 6,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isAligned
                      ? const Color(0xFF10B981)
                      : const Color(0xFFE53935),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isAligned
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE53935))
                          .withValues(alpha: 0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Information cards below compass
  Widget _buildInfoCards(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.explore_rounded,
                iconColor: const Color(0xFFD97706),
                title: l10n.qiblaAngle,
                value: '${_qiblaAngle.toStringAsFixed(1)}°',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.navigation_rounded,
                iconColor: const Color(0xFF003D82),
                title: l10n.currentHeading,
                value: '${_currentHeadingDegrees.round()}°',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.place_rounded,
                iconColor: const Color(0xFF059669),
                title: l10n.distanceToKaaba,
                value: _distanceToKaabaKm > 0
                    ? '${_distanceToKaabaKm.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} km'
                    : '-',
              ),
            ),
            if (_displayAddress != null && _displayAddress!.isNotEmpty) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Lokasi',
                  value: _displayAddress!,
                ),
              ),
            ] else if (_currentPosition != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFF6366F1),
                  title: 'Lokasi',
                  value:
                      '${_currentPosition!.latitude.toStringAsFixed(2)}°, ${_currentPosition!.longitude.toStringAsFixed(2)}°',
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  /// Shown when the device lacks magnetometer / compass sensor
  Widget _buildUnsupportedDeviceView(AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFECACA), width: 2),
              ),
              child: const Icon(
                Icons.sensors_off_rounded,
                color: Color(0xFFDC2626),
                size: 46,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.deviceNotSupported,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.deviceNotSupportedDesc,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // If GPS is available, show manual Qibla data card so user can still know the angle
            if (_currentPosition != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.explore_rounded,
                          color: Color(0xFF003D82),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.qiblaAngle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        Text(
                          '${_qiblaAngle.toStringAsFixed(1)}°',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003D82),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          color: Color(0xFF059669),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.distanceToKaaba,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                        Text(
                          '${_distanceToKaabaKm.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} km',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            OutlinedButton.icon(
              onPressed: _initQiblaFeature,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.tryAgain),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card requesting location permission
  Widget _buildLocationPermissionCard(AppLocalizations l10n) {
    final isPermanent =
        _locationPermission == LocationPermission.deniedForever;

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
              l10n.locationPermissionDesc,
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
                  // On iOS, deniedForever means we must redirect to Settings
                  await Geolocator.openAppSettings();
                  // WidgetsBindingObserver.didChangeAppLifecycleState will handle
                  // re-checking permission when user returns from Settings
                } else {
                  // Re-run full init flow which requests permission and sets up compass
                  _initQiblaFeature();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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
  Widget _buildLocationDisabledCard(AppLocalizations l10n) {
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
                _initQiblaFeature();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
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
